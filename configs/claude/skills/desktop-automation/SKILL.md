---
name: desktop-automation
description: Drive the NixOS + Hyprland desktop programmatically, preferring semantic accessibility-tree actions over screenshots and pixel coordinates. Use when a task requires headful UI interaction, visual verification, or browser automation.
---

# desktop-automation

**What**: Tools and patterns for driving the NixOS + Hyprland desktop without human input.
**Why**: Some tasks genuinely need a real UI — testing click flows, verifying visual output, pasting into a running TUI. This is a yolo box; treat the desktop like any other tool.

---

## Session env — set this first if SSH'd in

`WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE` are unset in SSH sessions. Set the session bus too so `xa11y` can reach AT-SPI.

```sh
export WAYLAND_DISPLAY="$(ls /run/user/$(id -u)/ | grep -E '^wayland-[0-9]+$' | head -1)"
export HYPRLAND_INSTANCE_SIGNATURE="$(ls /run/user/$(id -u)/hypr/ | head -1)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
```

---

## Choose the highest-level control surface

Use the first available option:

1. **Application protocol** — CDP/Playwright for browsers, PTY/tmux for terminals, CLI/API for coding agents.
2. **`xa11y` accessibility tree** — default for native desktop UI and browser chrome. Address widgets by role, name and state; invoke their native actions.
3. **Targeted keyboard input** — Hyprland `sendshortcut` or `wtype` when the UI has no usable accessibility action.
4. **Cropped screenshot + raw pointer** — last resort for canvas, WebGL, custom-rendered controls and visual verification.

Do not take a screenshot merely to discover a button that `xa11y find` can return as a few lines of text.

---

## The loop — always observe → act → verify

Fire-and-forget doesn't work. Every desktop action follows this cycle:

1. **Observe** — query the relevant element or shallow subtree with `xa11y`.
2. **Act** — invoke the element's advertised accessibility action.
3. **Verify** — query the expected name, value or state; use an accessibility event when waiting for an asynchronous change.
4. **Fall back** — only use a cropped screenshot and raw input when the tree is absent or incomplete.

If verification fails, re-observe before retrying. An `ok` action means the application accepted it, not that the UI necessarily changed.

---

## `xa11y` — preferred desktop interface

AT-SPI is Linux's equivalent of Android's accessibility/UIAutomator tree. It exposes applications, windows, buttons, text fields, tabs, names, values, states and native actions over D-Bus.

Start narrow. Do not repeatedly dump a whole application tree:

```sh
xa11y apps
xa11y tree --app pavucontrol --max-depth 3 --max-nodes 100
xa11y find 'button[name="Advanced"]' --app pavucontrol
xa11y action press 'button[name="Advanced"]' --app pavucontrol
xa11y find 'button[name*="Advanced"]' --app pavucontrol
```

Useful actions:

```sh
xa11y action press 'button[name="Save"]' --app APP
xa11y action focus 'text_field[name="Search"]' --app APP
xa11y action set-value 'text_field[name="Search"]' --app APP --value 'query'
xa11y action toggle 'check_box[name="Enabled"]' --app APP
xa11y find 'tab[selected="true"]' --app APP
xa11y events --app APP --kinds state_changed,value_changed,text_changed
```

Rules:

- Prefer `action` to `click`. It calls the widget itself and normally needs neither focus nor coordinates.
- Use selectors that match exactly one element. Narrow ambiguous matches by name, hierarchy or `:nth(n)`.
- Verify the resulting property or a changed subtree instead of taking a screenshot.
- If `xa11y` reports `not_delivered`, a corrected retry is safe. If delivery is `unknown`, re-read state first.
- On Wayland, accessibility bounds are not reliable global screen coordinates. Do not turn a `find` result into a pixel click; use its native action.

### Browser and toolkit notes

- Brave, Chrome, VS Code and Cursor are packaged with `--force-renderer-accessibility` in this Nix configuration.
- GTK applications normally expose their tree directly.
- Firefox can expose page elements with `MOZ_ACCESSIBILITY_ATK2=1`, but on worker207/Wayland it reported those elements as `not_showing`; `xa11y` correctly refused to press them. Use CDP for Firefox/web content rather than bypassing that safety check.
- Canvas, WebGL, some Flutter apps and custom widgets may expose little or no useful tree. Use the fallback path for those regions only.

If `xa11y apps` unexpectedly returns nothing, check that the accessibility flags are enabled:

```sh
busctl --user get-property org.a11y.Bus /org/a11y/bus org.a11y.Status IsEnabled
busctl --user get-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled
```

On a session without a settings daemon, enable them before launching the target application:

```sh
busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status IsEnabled b true
busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled b true
```

---

## Toolchain

| Tool | Use for | Notes |
|---|---|---|
| `xa11y` | Inspect and act on semantic UI elements | Preferred for desktop UI; avoid pixels entirely |
| `hyprctl dispatch "hl.dsp.send_shortcut({mods='SUPER', key='m', window='class:^(app)$'})"` | Key chord to a specific window — **bypasses focus** | Preferred over wtype when you know the target class |
| `wtype` | Free-form text or chords to focused window | `wtype -M ctrl -p v -m ctrl` = Ctrl+V |
| `ydotool` | Mouse clicks and moves | Needs `ydotoold` running + user in `ydotool` group |
| `hyprctl clients -j` | List all windows with class, title, geometry | Always locate before acting |
| `grim -g "X,Y WxH" /tmp/out.png` | Screenshot a region | Pull geometry from `hyprctl clients -j` |
| `hyprctl dispatch "hl.dsp.exec_cmd('[float; size W H; center 1] cmd')"` | Launch floating window centred | Good for browser UI tests |

**If `ydotool` fails with permission denied:** check `id` for `ydotool` group membership. For keys-only, fall back to `wtype` or `sendshortcut` instead.

---

## Screenshots — visual verification and last resort

Multiple full-screen screenshots accumulate in context and Claude rejects requests once cumulative dimensions exceed ~2000px.

- **Query `xa11y` first** — names, values and states are cheaper and more precise than pixels
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
