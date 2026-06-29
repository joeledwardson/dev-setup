# Local voice dictation (hyprwhspr-rs) — push-to-talk Whisper speech-to-text that
# types into the focused window. Fully local, no API key. Imported by jollof-home only.
#
# Replaces the hand-rolled whisper.cpp + wtype + swhkd stack — one daemon does
# hotkey + record + transcribe + inject. See ADR-005 and dev-log 2026-06.
#
# What this module owns:
#   - the hyprwhspr-rs daemon package + wtype (one of its text-injection backends)
#   - the GGML model, fetched reproducibly into the Nix store and symlinked into place
#   - the systemd --user service
#
# NOT owned here: ~/.config/hyprwhspr-rs/config.jsonc is deployed by dotbot
# (configs/hyprwhspr-rs/config.jsonc) so the editable config stays in git, not the Nix store.
#
# Gotcha this module fixes: `hyprwhspr-rs install --service` generates a BROKEN unit whose
# ExecStart points at the inner `.hyprwhspr-rs-wrapped`, bypassing the wrapper that puts
# `whisper-cli` on PATH — so the daemon dies with "No whisper binaries found". We declare our
# own unit pointing at the wrapper instead.
{ pkgs, pkgs-unstable, ... }:
let
  # whisper.cpp GGML model. NOTE: this is a different file format from the CTranslate2
  # models that `whisper-ctranslate2` uses — they are not interchangeable.
  # base.en: 140 MB, ~400ms latency, best size/accuracy balance for dictation.
  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };
  # %h is a systemd-tmpfiles specifier that expands to each user's home dir, so this module
  # is user/host-agnostic — no hardcoded /home/jollof. (Works in user tmpfiles, below.)
  modelsDir = "%h/.local/share/hyprwhspr-rs/models";
in
{
  environment.systemPackages = [
    pkgs-unstable.hyprwhspr-rs # the dictation daemon
    pkgs.wtype                 # Wayland keystroke injection backend
    pkgs.sox                   # audio utilities (level checks, resampling)
  ];

  # Drop the fetched model into the dir hyprwhspr-rs scans (config: transcription.whisper_cpp.models_dirs).
  # USER tmpfiles (run per-user) so %h resolves and the symlink is owned by the user, not root.
  # `d` ensures the dir exists on a fresh machine; `L+` creates/replaces the symlink to the store path.
  systemd.user.tmpfiles.rules = [
    "d ${modelsDir} 0755 - - -"
    "L+ ${modelsDir}/ggml-base.en.bin - - - - ${whisperModel}"
  ];

  # Declarative replacement for the broken `install --service` unit (see header).
  systemd.user.services.hyprwhspr-rs = {
    description = "hyprwhspr-rs voice dictation";
    after = [ "graphical-session.target" "pipewire.service" ];
    wants = [ "pipewire.service" ];
    # Bound to the graphical session (not default.target) so it cycles with the
    # compositor and picks up the freshly-finalized Wayland env on each restart.
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # whisper-cli is already baked into the wrapper's PATH; wtype is here for the injection fallback.
    path = [ pkgs.wtype ];
    environment.RUST_LOG = "info";
    serviceConfig = {
      # The WRAPPER (sets PATH so whisper-cli is found), not the inner .hyprwhspr-rs-wrapped.
      ExecStart = "${pkgs-unstable.hyprwhspr-rs}/bin/hyprwhspr-rs";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
