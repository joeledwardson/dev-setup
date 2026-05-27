---
name: desktop-automation
description: Drive the NixOS + Hyprland desktop programmatically — window focus, keyboard input, screenshots, clipboard, VNC, and Chromium via CDP. Use when a task requires headful UI interaction, visual verification, or browser automation.
---

# desktop-automation

**What**: Tools and patterns for driving the NixOS + Hyprland desktop without human input.
**Why**: Some tasks genuinely need a real UI — testing click flows, verifying visual output, pasting into a running TUI. This is a yolo box; treat the desktop like any other tool.

---

## Session env — set this first if SSH'd in

`WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE` are unset in SSH sessions. Everything below fails silently without them.

```sh
export WAYLAND_DISPLAY="$(ls /run/user/$(id -u)/ | grep -E '^wayland-[0-9]+$' | head -1)"
export HYPRLAND_INSTANCE_SIGNATURE="$(ls /run/user/$(id -u)/hypr/ | head -1)"
```

---

## The loop — always observe → act → verify

Fire-and-forget doesn't work. Every desktop action follows this cycle:

1. **Observe** — `hyprctl activewindow -j` or `grim /tmp/out.png` + `Read` the PNG
2. **Act** — send keys, click, navigate
3. **Verify** — screenshot again, diff against expectation

If step 3 doesn't show the expected change, re-observe before retrying. Don't blindly retry — the window focus, a modal, or the element position may have changed.

---

## Toolchain

| Tool | Use for | Notes |
|---|---|---|
| `hyprctl dispatch sendshortcut KEY,class:^(app)$` | Key chord to a specific window — **bypasses focus** | Preferred over wtype when you know the target class |
| `wtype` | Free-form text or chords to focused window | `wtype -M ctrl -p v -m ctrl` = Ctrl+V |
| `ydotool` | Mouse clicks and moves | Needs `ydotoold` running + user in `ydotool` group |
| `hyprctl clients -j` | List all windows with class, title, geometry | Always locate before acting |
| `grim -g "X,Y WxH" /tmp/out.png` | Screenshot a region | Pull geometry from `hyprctl clients -j` |
| `hyprctl dispatch exec "[float; size W H; center 1] cmd"` | Launch floating window centred | Good for browser UI tests |

**If `ydotool` fails with permission denied:** check `id` for `ydotool` group membership. For keys-only, fall back to `wtype` or `sendshortcut` instead.

---

## Screenshots — avoid the 2000px context limit

Multiple full-screen screenshots accumulate in context and Claude rejects requests once cumulative dimensions exceed ~2000px.

- **Default to region grabs**: `grim -g "X,Y WxH"` — pull the rect from `hyprctl clients -j`
- **One screenshot per step** — if you confirmed the state, don't screenshot again "just to be sure"
- **For browser UI**: use CDP `Page.captureScreenshot` with a clip region instead of grim

---

## Clipboard

```sh
wl-copy --type image/png < file.png   # load image with correct MIME type
wl-paste -l                           # verify what's on clipboard
wl-copy --clear                       # teardown
```

`WAYLAND_DISPLAY` must be set (see above).

---

## VNC (wayvnc) — viewing the desktop remotely

wayvnc does not autostart. Check first:

```sh
ss -tlnp | grep 5900
```

If nothing listening, start in a tmux pane:

```sh
export WAYLAND_DISPLAY=wayland-1 && export XDG_RUNTIME_DIR=/run/user/$(id -u)
wayvnc -L info 0.0.0.0 5900
```

**Auth gotchas** — config at `~/.config/wayvnc/config`:
- Want no auth: set `enable_auth=false`
- Remmina + wayvnc 0.9+ = "Unknown authentication" error — use **TigerVNC** (`vncviewer host::5900`) or switch Remmina to GTK-VNC backend

---

## Chromium via CDP (preferred for web UI)

CDP (Chrome DevTools Protocol) beats wtype + screenshots for browser testing — no focus handling, no pixel coordinates, direct DOM access.

**Launch:**
```sh
brave --remote-debugging-port=9998 --user-data-dir=/tmp/brave-test &
# verify: curl -s http://localhost:9998/json/version
```

Use a fresh `--user-data-dir` if a normal instance is already running — otherwise the flag is silently ignored.

**Drive (Node 22+ stdlib WebSocket):**
```js
const targets = await fetch('http://localhost:9998/json/list').then(r => r.json());
const ws = new WebSocket(targets.find(t => t.type === 'page').webSocketDebuggerUrl);
// send({method, params}) helper — see unattended skill for full pattern
await send('Page.navigate', { url: 'http://localhost:9585' });
const { result } = await send('Runtime.evaluate', { expression: 'document.title' });
```

**Methods you'll actually use:**
- `Page.navigate` — go to URL
- `Runtime.evaluate` — run JS, get result back (covers 90% of clicking/scraping)
- `Page.captureScreenshot` with `clip` — region screenshot without grim

**Don't connect to the user's logged-in browser profile.**

---

## When not to use this

- Don't automate the user's accounts, messaging apps, or anything touching their identity
- If 3 observe→act→verify cycles fail on the same step — stop, log, the UI model is wrong
- Don't steal focus while the user is actively using the machine
