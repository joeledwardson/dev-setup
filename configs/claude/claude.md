# Workflow
- Be concise — cut filler, sacrifice grammar for brevity where it doesn't hurt clarity. BUT "concise" means removing empty words, NOT compressing domain jargon into unreadable density. When summarising technical work (debug findings, investigation results, multi-step completions): lead with a one-line plain-language answer ("what happened / why / next step"), expand acronyms on first use in a new topic, then give the detail. Stacking 5+ unexplained domain terms in a row is compression past usefulness — if the user asks "in English please?" or "what?", you over-compressed. That's a bug, not concision. Applies to chat, code edits, and short answers.
- always remember to think "in english please" that a stupid human can understand
- For long-form artifacts (research reports, analysis docs, design docs, anything >2 screens): optimise for the reader re-reading, not for brevity. Lead with a TL;DR (≤5 standalone findings), expand acronyms on first mention (`SDE (Seller's Discretionary Earnings)`), end each section with a "so what" line, use tables for any X-vs-Y or ">2 items same attributes" comparison, pair abstract claims with concrete examples. Ban tease-forward filler ("informs X", "sets context for Y", "provides plumbing for Z") — replace with the actual finding. Prefer the `/research` skill for these.
- Where possible, give links to documentation and online sources
- Be brutally honest, don't be a yes man. If I am wrong, point it out bluntly. 
- Do NOT add additional code I did not specify - ask yourself is this actually required according to the question
- check for existing functions before re-inventing the wheel - for example do not write a python sorting file just use array.sort
- for reading files - prefer Read/Glob/Greb over awk/sed as you gave permissions to the former
- do not use single letter variable names
- i frequently use scrollback buffer in zellij to copy commands - do not output your standard ● before commands or code to copy for ergonomics
- when asked to "read terminal output" or "pane output" (or something to that effect) - use a combination of zellij action list-panes and zellij action dump-screen --pane-id to get the terminal output
- when reading terminal output (from above) - execute zellij action as single commands then analyze in your internal buffer (dont chain bash commands, as i will have to approve them) - you have permissions to zellija ction list-panes and dump-screen
- prefer grep and rg (blank permissions applied) over awk/sed for search operations - the latter requires approval
- when writing code ALWAYS ask yourself this: a) is this required? b) can a human read this, is it ergonomic? c) is there a clearer way to do this? d) prioritise clear and easy to follow structure (e.g. early return syntax)
- where possible - do NOT pipe bash commands - then it ignores any pre-set permissions i have given for Find:* Grep:* etc

# Per-project ports (multi-Claude on one host)
- Multiple Claude sessions run on this machine in parallel and used to clash on the conventional dev-server defaults (3000, 5173, 8000, 8080, 8765, 6006, 9000). Each project gets a deterministic port block instead.
- **Reserved port: `9999` is reserved for `port-dash` (the global port dashboard). Never allocate it to a project.**
- Allocation rule: base port = `9000 + CRC32(<project-name>) % 900`. Pin contiguous offsets from there (api = base, frontend = base+1, storybook = base+2, observability = base+3..). Compute once and write the numbers into the repo's `justfile` / `docker-compose.yml` / equivalents — the hash is just how to *pick*; once written, the numbers are authoritative.
- New project: derive base via `uv run python -c "import zlib; print(9000 + zlib.crc32(b'<project>') % 900)"` (or the language equivalent), assign offsets, document in the repo's CLAUDE.md (per the schema below), and add a preflight step to the dev-server recipes that fails loudly when a port is held by another process (printing pid+cmdline). Don't pick a fallback port — fix the conflict.
- Never start a server with a hardcoded conventional default. Never let Vite/uvicorn auto-pick — that breaks proxy chains and bookmarks.
- Long-running dev servers (api, frontend, storybook, observability) run inside named cowork panes — pane name = `<project>-<service>` (e.g. `face-stream-api`, `face-stream-frontend`). Before spawning, list panes and reuse an existing one rather than starting a duplicate that will fail preflight.
- **Every repo's CLAUDE.md MUST include a parsable port block** — lets tooling (the cross-session port dashboard, preflight checks) discover allocations without regex-scraping `justfile`/`docker-compose.yml`. Format: fenced ``` ```toml ``` block under a top-level `## Ports` heading, containing a single `[ports]` table.
  - **Service-name keys** use the fixed set: `api`, `frontend`, `storybook`, `observability`. For anything else, use a nested `[ports.extras]` table (`name = port`).
  - **Pane → port linking is implicit** via the `<project>-<service>` pane-name convention — no need to declare `pane = ...` per entry. If a repo deviates from the convention, add `pane = "<name>"` inline.
  - The numbers in `[ports]` are the source of truth — must match what's in `justfile` / `docker-compose.yml` / equivalents. The CRC32 rule is only how to *pick* on first allocation.

  <details><summary>Example block</summary>

  ````markdown
  ## Ports

  Base port `9123` (from `crc32("face-stream") % 900 + 9000`).

  ```toml
  [ports]
  api       = 9123
  frontend  = 9124
  storybook = 9125

  [ports.extras]
  vector-tile-server = 9126
  ```
  ````
  </details>
