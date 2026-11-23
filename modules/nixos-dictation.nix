# Local, system-wide dictation for the four regular desktop hosts. Hyprwhspr-rs
# records and types into the focused window; Parakeet v3 does transcription on CPU.
# The editable config is linked by dotbot from configs/hyprwhspr-rs/config.jsonc.
{ pkgs, pkgs-unstable, ... }:
let
  parakeetModel = pkgs.callPackage ./parakeet-model.nix { };
  modelsDir = "%h/.local/share/hyprwhspr-rs/models";
in
{
  environment.systemPackages = [
    pkgs-unstable.hyprwhspr-rs
    pkgs.wtype
    pkgs.sox
  ];

  # %h resolves to each user's home in the user tmpfiles service.
  systemd.user.tmpfiles.rules = [
    "d ${modelsDir} 0755 - - -"
    "d ${modelsDir}/parakeet 0755 - - -"
    "L+ ${modelsDir}/parakeet/parakeet-tdt-0.6b-v3-onnx - - - - ${parakeetModel}"
  ];

  systemd.user.services.hyprwhspr-rs = {
    description = "hyprwhspr-rs voice dictation";
    after = [ "graphical-session.target" "pipewire.service" ];
    wants = [ "pipewire.service" ];
    # Restart with each graphical session to pick up its Wayland environment.
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.wtype ];
    environment.RUST_LOG = "info";
    serviceConfig = {
      ExecStart = "${pkgs-unstable.hyprwhspr-rs}/bin/hyprwhspr-rs";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
