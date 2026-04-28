---
name: unattended
description: Switch to unattended/solo mode for research and long-running work on yolo boxes. When invoked, push through friction instead of pausing for the user. Only invoked on explicit /unattended — never auto-load.
disable-model-invocation: true
---

# unattended — push through, don't wait

You're on a yolo box doing research or a long-running task. The user is not watching and does not want to be pinged every 5 minutes. Default to *doing* rather than *asking*.

This does **not** mean "never ask". It means: ask only when genuinely blocked. If a question can be turned into an action, take the action.

## Default stance

Normal mode: "ask if unsure" → unattended mode: "act if unsure, and explain in the log what you chose".

When you hit something ambiguous, pick a reasonable option, record it in the log, and keep going. The user will review the log when they come back and tell you if you chose wrong.

## Worked examples (translate questions into actions)

1. **"I tried to fix this bug but found a problem in <dependency>"**
   → Clone the dependency, set up its env, reproduce, debug locally. Patch via fork or vendor if the upstream fix won't land in time. Don't stop.

2. **"The fix is done, ready for review"**
   → Not yet. Write/update tests. Run the full test suite. Exercise the change end-to-end (run the thing, hit the endpoint, open the UI). Only then say it's done.

3. **"I have an architectural decision to make between A and B"**
   → Research online (official docs, well-known engineering blogs) for the simplest / most ergonomic / most performant option. If the tradeoffs are still unclear, create two branches, implement both, compare empirically (benchmarks, ergonomics, line count), then pick. Log the comparison.

4. **"I need to install <tool> to try X"**
   → Install it. You have privileges on yolo boxes. Use the native package manager (Nix on NixOS boxes — add to the right module if it should persist, else `nix shell`). Don't ask permission for dev tools.

5. **"The test suite is flaky — should I retry?"**
   → First, try to identify whether flakiness is infra (retry) or real (investigate). If infra, retry up to 3x. If real, fix it or log the exact reproduction and move on to other tractable work.

6. **"I'm stuck on this one task, should I ask?"**
   → Time-box it (see guardrails). If you've spent the budget, park the task with a clear writeup in the log and move to the next task. Don't sit on a blocker.

## Guardrails — when to still stop

Unattended doesn't mean reckless. Stop and wait for the user when:

- **Credentials / auth**: You need a password, token, 2FA, or any human identity check the user hasn't already scripted. Don't guess, don't fake.
- **Destructive on shared state**: Force-pushing shared branches, dropping prod-adjacent databases, deleting other users' work, rm-rf on anything outside the project, rewriting published git history.
- **Paid operations**: Anything that spends real money (cloud resources beyond free tier, paid API upgrades, domain registration). Estimate first, log, ask.
- **Scope explosion**: Task was "fix this bug" but the real fix is "rewrite this subsystem". Log the divergence and stop — user decides scope.
- **Truly ambiguous intent**: The instruction has two plausible readings with materially different outcomes. Pick the less-destructive one and ask, or log both options.
- **Repeated failure on the same thing**: You've retried the same approach 3+ times with the same failure. Stop, log, try a different angle or wait for input.

## Time-boxing

- Single bug: max ~2 hours of active attempts before parking and moving on.
- Architectural experiment: max 1 day per branch before stopping to compare.
- Research: max ~30 min reading before starting to prototype.

Budgets are soft. Log when you exceed them, don't pretend you didn't.

## The log

The user isn't watching. Write a running log so they can catch up later. Append to `DEV-LOG.md` at the project root (create it if missing). One entry per meaningful event:

```
## 2026-04-22 14:03 — <short title>
Context: what I was doing.
Action: what I did / chose.
Why: reasoning in one or two sentences.
Result: outcome, test evidence, next step.
```

Don't log every bash command — log decisions, blockers, pivots, completions. The log is for the user to skim on return, not a transcript.

## Commits in unattended mode

Override the default "never commit unless explicitly asked" rule from the Claude Code system prompt. The user reviews via `git log` / diff when they return, not by watching you work — so commit frequently in small logical units with clear messages.

Scope:

- **DO** commit work *you produced* as part of the current task.
- **DO** commit obviously-safe hygiene you generated (gitignore additions, lockfiles you just regenerated, formatting on files you edited).
- **DO NOT** commit pre-existing uncommitted changes the user had in progress before you started — that's their work, not yours. Leave it alone.
- **DO NOT** push unless explicitly asked. Local commits are reversible; pushes hit shared state (still covered by the Guardrails section above).
- **DO NOT** amend or rewrite commits that aren't yours, even locally.

If unsure whether a change is "yours" or "theirs", check `git log` / `git status` against the state when the task started — and if still ambiguous, leave it.

## Desktop automation on NixOS + Hyprland

When a task truly needs headful interaction (testing web UIs, verifying click flows, reproducing a GUI bug, pasting an image into a running TUI), drive the desktop instead of asking the user. This is a yolo box — treat the desktop like any other tool.

### Session env (the SSH caveat — set this first)

If you're SSH'd in, `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE` are unset by default. `hyprctl` fails with "HYPRLAND_INSTANCE_SIGNATURE not set!", `wl-copy` / `wtype` fail silently. Export both once before anything else:

```sh
export WAYLAND_DISPLAY="$(ls /run/user/$(id -u)/ | grep -E '^wayland-[0-9]+$' | head -1)"
export HYPRLAND_INSTANCE_SIGNATURE="$(ls /run/user/$(id -u)/hypr/ | head -1)"
```

### Viewing the desktop remotely (wayvnc)

If the user wants to watch the headful automation, they connect a VNC client. `wayvnc` is the Wayland-native VNC server. **It does not autostart** — if the user asks why VNC isn't working, first check it's running.

```sh
ss -tlnp | grep 5900   # is anything listening?
```

If not, launch it in a tmux window so the user can see logs:

```sh
export WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR=/run/user/$(id -u)
wayvnc -L info 0.0.0.0 5900
```

Bind `0.0.0.0` to reach it over Tailscale; `127.0.0.1` if SSH-tunneling. **Don't expose 5900 to the public internet** — auth is brittle (see below).

#### Auth gotchas

Config lives at `~/.config/wayvnc/config`. Default in this repo is:

```
enable_auth=true
username=claude
password=CHANGEME
```

If the user reports auth failure, **read this file first**. The two common cases:

- **Want no auth:** set `enable_auth=false` (only line needed). Restart wayvnc.
- **wayvnc 0.9+ + Remmina = "Unknown authentication" error.** wayvnc unconditionally advertises RSA-AES-256 (RFB security type 1129) which Remmina's libvncclient backend doesn't speak. Fix: use **TigerVNC viewer** (`vncviewer 100.x.y.z::5900` — note the `::` for raw port) or switch Remmina's backend to GTK-VNC.
- **"Invalid username or password" in logs** = auth IS enabled and creds don't match. Either set creds correctly client-side, or disable auth.

#### Common pitfalls

- `WAYLAND_DISPLAY is not set` from wayvnc = you forgot the env vars (or sent them via `tmux send-keys` and the first chars got eaten — `export` then run as separate commands).
- 4K HDMI output → VNC client appears massively zoomed. In Remmina: Resolution → "Fit to client window". In TigerVNC: F8 → Options → Screen → Scale to window.
- wayvnc is single-tenant — kill before restarting (`Ctrl+C` in its tmux pane), don't try to bind a second one to the same port.

### The toolchain

- **`wtype`** — Wayland virtual-keyboard client. Keys, chords, text. No `uinput`, no root. Sends to whatever window currently has keyboard focus. Example: `wtype -M ctrl -p v -m ctrl` = Ctrl+V. Good default for typing/chords.
- **`hyprctl dispatch sendshortcut KEY,CHAR,class:^(foo)$`** — fires a key chord at a window selected by class/title regex, **bypasses focus entirely**. Prefer this over `wtype` when you know the target. Example: `hyprctl dispatch sendshortcut "CTRL,V,class:^(kitty)$"`.
- **`ydotool`** — uinput-level dispatcher. Needed for mouse (clicks, moves, drags) and when a key event has to look like real hardware. Requires `ydotoold` running (usually is) **and** your user in the `ydotool` group — the socket is `0660 root:ydotool`. If you see `failed to connect socket '/run/ydotoold/socket': Permission denied`, stop: check `id` / `getent group ydotool`. For keys only, fall back to `wtype` or `sendshortcut`. For clicks, there's no non-root fallback — ask the user. Button code `0xC0` = left click.
- **`hyprctl dispatch`** — Hyprland's IPC for window actions: `focuswindow`, `movewindow`, `workspace`, `togglefloating`, `closewindow`, `exec` (with `[float; size W H; center]` prefix for rule injection). Not for arbitrary pixel clicks.
- **`hyprctl clients -j`** / **`hyprctl activewindow -j`** — JSON view of the window tree. Locate by class/title *before* acting, rather than guessing coordinates. Gotcha: `activewindow` returns `Invalid` when no window has keyboard focus (common right after a headless `dispatch exec`) — not a bug, just means no seat focus yet.
- **`hyprshot`** — convenience screenshot tool. `-m window -m active` for active window, `-m region` for a rect, `-m output` for full screen. Fails with `invalid geometry` if `activewindow` is Invalid — fall back to `grim`.
- **`grim`** — raw wlroots screenshot, no window-state dependency. `grim /tmp/out.png` for full screen, `grim -g "X,Y WxH" /tmp/out.png` for a rect (pull the geometry out of `hyprctl clients -j`). Outputs PNG you can `Read` to verify state.

#### Screenshot context budget — avoid the 2000px many-image limit

Claude Code rejects requests where multiple in-context images exceed a cumulative ~2000px dimension (`An image in the conversation exceeds the dimension limit for many-image requests (2000px)`). E2E loops that take 5+ full-screen `grim` shots will hit this mid-session.

Mitigations, in order:

1. **Default to region grabs, not full screen.** `grim -g "X,Y WxH"` — pull the rect from `hyprctl clients -j`. A 600×300 region is plenty for "did the Find bar open", "did the toast appear", "what's in this dropdown".
2. **One verification screenshot per step, not three.** If you took a screenshot and confirmed the state, don't take another "just to be sure" — it stays in context forever.
3. **Throw away once verified.** If an old screenshot no longer carries information you need (e.g. the page has since changed), the image still sits in context. There's no in-session way to drop it — only `/compact` or a fresh session clears it. Plan accordingly: if you know you'll need 10+ screenshots in a single task, warn the user up front that they may need to `/compact` once during the run.
4. **For Chromium UIs, use CDP `Page.captureScreenshot` with a clip region** rather than full-page grim — same idea, smaller payload, and you can grab DOM state via `Runtime.evaluate` instead of screenshotting at all.

### Clipboard

- **`wl-copy --type image/png < file.png`** — load an image onto the clipboard with a specific MIME type. Without `--type`, `wl-copy` infers text and image-aware apps won't find it.
- **`wl-paste -l`** — list MIME types currently on the clipboard. Sanity check after `wl-copy`.
- **`wl-copy --clear`** — empty the clipboard (teardown).
- Requires `WAYLAND_DISPLAY` set (see above).

### The loop

Fire-and-forget doesn't work. Always loop:

1. **Observe** — `hyprctl activewindow -j` and/or `grim /tmp/out.png`; `Read` the PNG to see actual state.
2. **Act** — `hyprctl dispatch sendshortcut ...` / `wtype ...` / `hyprctl dispatch ...` / `ydotool ...`.
3. **Verify** — screenshot again, diff against expectation, log the result.

If step 3 doesn't show the expected change, don't just retry — something is off (wrong window focused, modal on top, element moved, no seat focus after `exec`). Re-observe first.

### Common patterns

- **Launch and verify a browser for UI testing**:
  ```
  hyprctl dispatch exec "[float; size 1200 800; center 1] firefox --new-window http://localhost:3000"
  ```
  wait, `grim`, `Read`, confirm page loaded.
- **Send a key chord to a known window without stealing focus** (preferred over `wtype` when the target class is known):
  ```
  hyprctl dispatch sendshortcut "CTRL,V,class:^(kitty)$"
  ```
- **Focus a specific window before typing free-form text**:
  ```
  hyprctl dispatch focuswindow "class:^(firefox)$"
  wtype "hello"
  ```
- **Click a known element** (requires `ydotool` socket access):
  ```
  ydotool mousemove --absolute -x N -y M && ydotool click 0xC0
  ```

### Driving Chromium browsers via CDP (preferred for web UI work)

For testing a web UI in a Chromium-family browser (Brave, Chrome, Chromium), use CDP (Chrome DevTools Protocol) instead of `wtype`/`ydotool` + screenshots. You skip focus handling, pixel coordinates, and screenshot-diffing — you drive the page's JS runtime and DOM directly. Launch headfully so the user can watch over VNC if they want, or `--headless=new` if not.

#### Launch

```sh
brave --remote-debugging-port=9999 --user-data-dir=/tmp/brave-debug &
```

- `--user-data-dir` **must** be a fresh path if a normal Brave/Chrome instance is already running — otherwise the flag is silently ignored on the existing instance and the port never opens.
- Same flag for `chromium`, `google-chrome`, etc. (all Chromium-derived).
- Headful needs `WAYLAND_DISPLAY` / `DISPLAY` exported (see Session env above).
- Sanity check: `curl -s http://localhost:9999/json/version` → JSON with `Browser` + `webSocketDebuggerUrl`. Empty = port didn't open.

#### Discover targets

```sh
curl -s http://localhost:9999/json/list
```

Each tab/page has `id`, `url`, `type` (`page` for tabs), and `webSocketDebuggerUrl` — that ws:// URL is what you actually drive.

#### Drive via WebSocket (Node 22+ has it built in)

```js
const targets = await fetch('http://localhost:9999/json/list').then(r => r.json());
const page = targets.find(t => t.type === 'page');
const socket = new WebSocket(page.webSocketDebuggerUrl);
const pending = new Map();
let messageId = 1;

socket.addEventListener('message', event => {
  const msg = JSON.parse(event.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
});

const send = (method, params) => new Promise(resolve => {
  const cid = messageId++;
  pending.set(cid, resolve);
  socket.send(JSON.stringify({ id: cid, method, params }));
});

await new Promise(r => socket.addEventListener('open', r, { once: true }));
await send('Page.enable');
await send('Page.navigate', { url: 'https://example.com' });
const { result } = await send('Runtime.evaluate', { expression: 'document.title' });
console.log(result.result.value);
socket.close();
```

For anything beyond ad-hoc, prefer `puppeteer-core` or `playwright` with `connectOverCDP` against the already-launched Brave — same protocol, much nicer API.

#### Methods you'll actually use

- `Page.enable` — required before page events fire.
- `Page.navigate` `{ url }` — go to URL.
- `Page.captureScreenshot` `{ format: 'png' }` — base64 PNG; decode to a file and `Read` to verify visual state.
- `Runtime.evaluate` `{ expression }` — run arbitrary JS, get JSON back. Covers 90% of scraping/clicking — `document.querySelector('button').click()` is usually right answer over `Input.dispatchMouseEvent`.
- `Input.dispatchKeyEvent` / `Input.dispatchMouseEvent` — only when you actually need real input events (e.g. testing keyboard handlers).

#### Gotchas

- Multiple WS connections to the same target are fine; disconnect/reconnect doesn't reset page state.
- Re-running with the same `--user-data-dir` persists cookies/localStorage across runs. Fresh dir for isolation.
- `navigator.webdriver` is `false` for CDP-launched browsers — but bot-detection sites still fingerprint other tells. Playwright stealth modes if you need to defeat that.
- Don't connect CDP to the user's logged-in profile (see "When not to" below).

### When not to

- Don't automate the user's logged-in accounts, messaging apps, or anything touching their identity.
- Don't spam notifications or steal focus while the user is actively using the machine (if they're away, fine).
- If three observe→act→verify cycles fail on the same step, stop and log — the UI probably changed or your model of it is wrong.

## Integration with other skills

- **tmux-cowork**: use it aggressively in unattended mode. Long-running stuff goes in a named tmux pane so the user can see it when they attach.
- **PRs**: keep them small. Unattended does not mean one giant PR. Open a PR per logical unit of work as you finish each.

## On finishing

When you genuinely run out of tractable work:
1. Log what you completed and what's parked.
2. Summarize blockers that need user input, with proposed resolutions for each.
3. Stop. Don't invent work to stay busy.
