---
title: "2026-06-12 — Hypr Lua Fixes"
---

# Review — 2026-06-12 — hyprland 0.55 lua fixes

Scope: `configs/hypr/hyprland.lua`, `configs/hypr/scripts/flash-red.sh`,
`configs/hypr/scripts/toggle-special.sh`, `configs/hypr/.luarc.json` (uncommitted changes).

## Architectural (gemini, full repo)

- **DRIFT / ORPHANED — FLAG (pre-existing, not fixed)**: `configs/hypr/hyprland_OLD.conf` is an
  orphaned artifact of the conf→lua migration; `hyprpaper.conf` comments still reference the old
  conf. Left for the user to decide — deleting reference material unasked is not this change's call.
- **COUPLING — FLAG (pre-existing)**: lua config triggers `graphical-session.target` and writes
  `dconf` settings that could be declarative Nix. Existing design, out of scope.
- CONSISTENCY: CLEAN — colour variables unified, all scripts use the lua dispatch syntax.

## File: flash-red.sh

- **WEAK_CONTRACTS — FLAG (accepted)**: restore colour hardcoded, must match `active_colour` in
  `hyprland.lua`. Documented in the header comment; reviewer concedes dynamic query would be more
  complex than the problem warrants. Same contract existed before the change.
- All units LOGIC: CLEAR, SIMPLER: NO.

## File: toggle-special.sh

- **DIVERGENCE/LOGIC — FLAG (false positive, action taken)**: reviewer asserted
  `monitors .activeWorkspace.id` would return the special workspace's own id when a window is in
  special, breaking the "send back". Live E2E disproved this — with the window in `special:magic`,
  `.activeWorkspace.id` returned `1` and the window moved back correctly (special lives in
  `.specialWorkspace`). The flag still indicated an implicit contract → clarifying comment added.

## File: hyprland.lua

- **WEAK_CONTRACTS — FLAG (fixed)**: unused local `ensureService` (migration leftover) — removed.
- **WEAK_CONTRACTS — FLAG (accepted, pre-existing)**: exec-script binds are implicit contracts on
  script existence; `jq`-parsing binds (SUPER+SHIFT+T, SUPER+O) are brittle to output changes.
  Pre-existing pattern, out of scope.
- Submap units (`apply_border_colours`, `keybinds.submap` handler, `group_action`,
  `define_submap`): all LOGIC: CLEAR, SIMPLER: NO.

## Holistic

COHERENT: CLEAR · COMPLETE: CLEAR · SURPRISES: NONE.

## Iterations

1. Fixes applied: toggle-special clarifying comment, `ensureService` removal. Both
   non-behavioural; no second full pass run (within the 2-cycle budget).

Note: `/review-docs` not run — only `DEV-LOG.md` (append-only log, not a rendered docs page)
changed among markdown files.
