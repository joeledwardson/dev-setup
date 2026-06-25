---
title: "ADR-006 — Hyprwhspr Dictation"
---

# ADR-006 — Voice dictation: one daemon (`hyprwhspr-rs`) over hand-wired glue

**Status**: Accepted  
**Date**: 2026-06-20  
**Context**: I want push-to-talk dictation on Wayland/Hyprland — hold a key, speak, have the text typed into whatever window is focused (terminal, Claude Code prompt, browser). Fully local, no API key. An earlier attempt this month wired this by hand from three separate tools (`whisper.cpp` + `wtype` + `swhkd`); see *Local voice dictation on Linux* in dev-log 2026-06. This records the move to a single integrated daemon and how it's scaffolded in NixOS.

**Decision**: Use [`hyprwhspr-rs`](https://github.com/goodroot/hyprwhspr) — a single Rust daemon that owns hotkey + record + transcribe + inject — instead of gluing `swhkd` → `pw-record` → `whisper.cpp` → `wtype` myself. Same engine underneath (`whisper.cpp` for transcription, Wayland virtual keyboard / `wtype` for injection), one process to supervise. Scaffolded declaratively for **jollof-home** in `modules/nixos-dictation.nix`; the editable config stays in git and is symlinked by dotbot.

:::warning Does NOT cover
Model choice beyond `base.en` (small/medium are a one-line swap), the exact hotkey, and whether dictation lands on other hosts — jollof-home only for now (it has the GPU and the good mic).

:::

---

## Options considered

| Engine + injector | Wayland | Moving parts | Notes |
|---|---|---|---|
| **`hyprwhspr-rs`** | ✅ | **1 daemon** | ✅ Chosen — integrated hotkey/record/transcribe/inject |
| `whisper.cpp` + `wtype` + `swhkd` (hand-wired) | ✅ | 3 tools + glue | Works, but three things to keep in sync (the take-1 setup) |
| `whisper-ctranslate2 --live_transcribe` + custom wrapper | ✅ | 1 tool + my parser | **Rejected** — stdout-only, no inject mode; live output is dots + re-emitted partials, ugly to scrape |
| `nerd-dictation` (Vosk) | ❌ XWayland only | 1 tool | Breaks on native Wayland; lower accuracy than Whisper |

The real choice was *integrated daemon* vs *DIY glue*. Both run the same Whisper engine, so accuracy is identical — the daemon just removes the glue I'd otherwise own.

---

## Why not just wrap `whisper-ctranslate2`?

That was the instinct (it was already installed and transcribing). But `--live_transcribe` **only prints to stdout** — there is no keystroke-injection mode. To type into a window I'd have to scrape its live output, which interleaves progress dots and re-emitted partial hypotheses. `hyprwhspr-rs` is built for exactly "speak → text in the focused field", so the wrapper disappears.

Also worth recording: `hyprwhspr-rs` uses **whisper.cpp GGML** models (`ggml-base.en.bin`), a different file format from the **CTranslate2** models `whisper-ctranslate2` uses. They are not interchangeable, so the GGML model is fetched separately.

---

## How it's scaffolded (NixOS)

`modules/nixos-dictation.nix`, imported by `hosts/jollof-home/configuration.nix`:

- **Package**: `pkgs-unstable.hyprwhspr-rs` + `wtype` + `sox` (moved here from the shared `nixos-extended-desktop.nix`, where they were experimental and non-functional).
- **Model**: `fetchurl` the GGML `base.en` into the Nix store (reproducible, pinned by hash), then a `systemd.tmpfiles` `L+` rule symlinks it into `~/.local/share/hyprwhspr-rs/models/`.
- **Service**: a declared `systemd.user.services.hyprwhspr-rs` whose `ExecStart` is the **wrapper** `${pkgs.hyprwhspr-rs}/bin/hyprwhspr-rs` — *not* the inner `.hyprwhspr-rs-wrapped` that the tool's own `install --service` generates (that one bypasses the PATH wrapper and dies with "No whisper binaries found").
- **Config**: `~/.config/hyprwhspr-rs/config.jsonc` is deployed by **dotbot** from `configs/hyprwhspr-rs/` — config in version control, model in the Nix store.

:::info Three setup gotchas (full table in dev-log 2026-06)
1. Mic gain at 250% clips the condenser mic → Whisper returns gibberish. Keep `@DEFAULT_AUDIO_SOURCE@` at ~1.0.
2. The generated systemd unit points at the wrong (PATH-less) binary.
3. GGML ≠ CTranslate2 model format.

:::

---

## Consequences

- ✓ One process to supervise instead of three tools + glue scripts.
- ✓ Fully declarative + reproducible: package, model (hash-pinned), and service all in Nix; config in git via dotbot.
- ✓ Same Whisper accuracy as the hand-wired stack — no quality trade-off.
- ✗ Less granular control than owning each stage (e.g. custom VAD pipeline) — acceptable; the daemon exposes enough config (`config.jsonc`).
- ✗ jollof-home only for now. To enable elsewhere, import `modules/nixos-dictation.nix` in that host and confirm the mic.
- ↪ The take-1 `swhkd` + `wtype` + `whisper.cpp` notes remain in dev-log 2026-06 as the fallback reference if the daemon ever proves limiting.
