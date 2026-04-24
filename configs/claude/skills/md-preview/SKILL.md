---
name: md-preview
description: Serve a long-form markdown doc (research, analysis, notes, design doc, DEV-LOG) via mdview with live reload and share the Tailscale URL. Use after producing or updating any markdown file the user will read in a browser — research outputs, reports, competitive landscapes, strategic memos, running logs, anything >2 screens. Skip for short replies, code comments, commit messages, or build-artifact .md files.
---

# md-preview

When you produce or substantially update a long-form markdown file the user will read, **serve it immediately and give them a clickable URL**. Don't wait to be asked.

## Triggers

Invoke proactively after:

- Writing a research / analysis / design doc (especially from the `research` skill)
- Appending a meaningful section to a running log (DEV-LOG.md, research notes, session notes)
- Producing any `.md` output >2 screens the user will actually read

Skip when:

- The markdown is a one-line reply or a short snippet
- The file is a commit message, PR body, code-block dump, or build artifact
- The user explicitly said they'll read it in the terminal

## Steps

1. **Verify `mdview` is on PATH.** If missing, install via `uv` — it's the quickest path until `md-viewer-py` lands in nixpkgs:
   ```bash
   uv tool install md-viewer-py
   ```
   `uv` is already in `nixos-base.nix`, so this works on every box without extra setup. Tell the user you're installing it; don't do it silently.

2. **Reuse before spawning.** Check for an existing mdview bound to the same directory:
   ```bash
   pgrep -af "mdview.*$(realpath "$TARGET_DIR")" | head -1
   ```
   If one exists, read its port (from `ss -ltnp | grep mdview` or from your earlier tmux log) and reuse.

3. **Spawn the server.** Base command (both modes):
   ```bash
   mdview -p <port> --host 0.0.0.0 --no-browser <dir>
   ```
   - Port: default 9001; pick next-free if occupied.
   - `<dir>`: the directory containing the target `.md` file. md-viewer-py serves a folder, not a file.

   **Attended mode (default)** — run as a backgrounded Bash task (`run_in_background: true`). User is watching, can Ctrl+C, no need for tmux overhead.

   **Unattended mode (under `/unattended`)** — use the `tmux-cowork` skill so the server survives across the user's absence and is visible on attach:
   - Session: current project/dir basename
   - Pane title: `mdview-<port>`

4. **Emit the URL** in this shape, on its own line, so zellij/terminal autolink pickers grab it:

   ```
   http://<hostname>:<port>/
   ```

   Where `<hostname>` comes from the machine's Tailscale MagicDNS name (typically equal to `hostname`). Verify with:
   ```bash
   tailscale status --self --json 2>/dev/null | jq -r .Self.HostName
   ```
   If Tailscale isn't up, fall back to `127.0.0.1` and warn the user.

5. **Tell the user which file to click.** mdview opens at a file list — name the specific `.md` they should open.

## Example output

> Served `research-output.md` at http://streaming-server:9001/ — click `research-output.md` in the sidebar. Live reload via SSE; edit the file and the browser refreshes in <200ms. Running in tmux session `notes`, pane `mdview-9001`.

## Anti-patterns

- Spawning a new server per document — reuse the one for the folder.
- Binding to `127.0.0.1` on a remote box — Tailscale access breaks.
- Emitting the URL in prose ("you can view it at ...") — make it a bare URL on its own line so the terminal auto-links it.
- Forgetting to name the file to click — mdview lands on a file index.
