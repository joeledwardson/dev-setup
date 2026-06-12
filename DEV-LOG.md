# Dev Log

## 2026-06-12 17:17 — hyprland 0.55 lua migration fixes (flash-red, send-to-special, group submap)
Context: post-migration breakage on Hyprland 0.55.2 lua config.
Action: root-caused all three issues at runtime. (1) `hyprctl keyword` is rejected outright under the lua config ("can't work with non-legacy parsers") and runtime `hl.config` changes don't repaint the focused window until its focus state changes — fixed flash-red.sh and the submap colours using `hl.dsp.window.set_prop({prop='active_border_color', ...})`, which repaints immediately for grouped and non-grouped windows. (2) toggle-special.sh used `hl.dsp.focus({with_window=true})` (not a thing) — replaced with `hl.dsp.window.move({workspace=...})`. (3) Rebuilt the interactive_group submap: purple borders driven by the `keybinds.submap` event (fires with submap name on enter, '' on exit), full key set t/L/hjkl/u/n/p/,/. per the group-menu notification, esc/q exit.
Why: the old `define_submap` callback ran `set_red()` eagerly at config load (callback executes at definition time, verified by probe) — wrong hook entirely; the event is the correct one.
Result: all fixes verified by GUI E2E on the live compositor with screenshots (red flash + restore, special round-trip ws1→special→ws1, purple mode through a full h/n/u/escape key sequence driven by wtype). Also fixed `repeat_` → `repeating` on the resize binds (silent no-op before) and removed unused `ensureService` local.
Decisions: group mode is persistent (actions keep you in the mode; esc/q exit) — one-shot semantics would make "purple until exit" pointless; purple = rgba(c678ddff); kept group-menu.sh as the single SUPER+ALT+G entry point.
Watch-outs: unmatched keys implicitly reset lua submaps; wtype/virtual-keyboard input does NOT match binds unless `input.resolve_binds_by_sym=true` (used temporarily for testing, reverted) — ydotool would be the proper injector but needs ydotool group membership; groupbar tab colour can't repaint live (config-only change, no damage), so flash/purple covers borders only.

## 2026-06-12 17:17 — hl lua stubs wired into lua_ls
Context: checked whether Hyprland ships lua type stubs — it does: `share/hypr/stubs/hl.meta.lua` in the package, stable at `/run/current-system/sw/share/hypr/stubs/`.
Action: added `configs/hypr/.luarc.json` (same pattern as yazi's) pointing workspace.library at the stable path.
Result: E2E in nvim (tmux pane): lua_ls attached, zero undefined-global diagnostics, hover on `hl` resolves `(global) hl: HL.API` with full signatures.

## 2026-06-12 16:47 — Beelink Mini S12: auto power-on after power loss (not yet applied)
Context: explored options for the mini PC to switch itself back on after a power cut (currently needs the physical switch).
Action: hardware scan identified the box as a Beelink Mini S12 (AZW "MINI S", Intel N100, AMI BIOS ADLNV105 2023-12-12, Realtek RTL8111 NIC, rtc_cmos with wake-alarm support). Chosen option: BIOS `Chipset → PCH-IO Configuration → State After G3 → S0 State` — board powers on whenever mains returns. Not applied yet (needs physical access, user will do it later).
Why: it's a firmware NVRAM setting applied before any OS exists, so it cannot be set from NixOS. Runtime hacks (efivars `setup_var`, `setpci` on the PCH) risk bricking and were rejected.
Result: parked. Alternatives noted: Wake-on-LAN (NIC supports it, currently disabled at OS level — does not survive a full power cut, so not the fix) and RTC timed wake (BIOS `S5 RTC Wake Settings` or `rtcwake`). Watch-out: Beelink units with a flat CMOS battery lose BIOS settings, which would silently revert this.
