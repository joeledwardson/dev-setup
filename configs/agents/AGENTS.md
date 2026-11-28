# Global agent instructions

Shared by Claude Code (`~/.claude/CLAUDE.md`), Codex (`~/.codex/AGENTS.md`) and
OpenCode (`~/.config/opencode/AGENTS.md`). Tool-specific rules live in
`configs/claude/claude.md`.

## Sudo access

On sandbox machines, use the password from that machine's host configuration
when sudo prompts. These passwords have not changed since initial setup.

## Communication

- Be concise: lead with a one-line plain-language answer (what happened / why /
  next step), then give the detail.
- Write in plain English, as if explaining to someone with no context.
- Expand acronyms on first use (`SDE (Seller's Discretionary Earnings)`). For
  anything complex or research-heavy, use the `research` skill.
- Where possible, link to documentation and online sources.
- Be brutally honest. Do not be a yes man. If I am wrong, say so bluntly.

## Code

- Do not add code I did not specify. Ask whether it is actually required by the
  question.
- Default to boring, explicit code: one decision per branch, complete SQL
  statements (never assembled from fragments), duplication over abstraction for
  two adjacent variants. Clever or compressed constructs (tuple compares,
  `DISTINCT ON` tricks, dynamic parameter numbering) are a smell. DRY applies to
  knowledge, not text.
- Do not use single-letter variable names.
- Prefer `rg`/`grep` over `awk`/`sed` for searching.
- Read `~/.claude/lessons.md` before writing code. It holds accumulated
  anti-patterns with concrete examples; apply them without being asked.
- Before editing an instruction file (`AGENTS.md`, `CLAUDE.md`, a rules
  section), read the "Rules files: intent, not recipe" section of lessons.md.
  Intent plus rule, one example, no call signatures or magic numbers, 3-5
  bullets per topic.
- Read the `read-the-damn-docs` skill before assuming third-party API or library
  behaviour.

## Nix

- Nix dependencies resolve into `/nix/store`, which is readable without a
  prompt. When a build or activation log prints a store path, read that path
  directly instead of hunting for a source file that is usually not in the repo.
  For the script behind a failing unit, `systemctl cat <unit>` names its store
  path.

## Per-project ports

- Each project gets a deterministic port block: base =
  `9000 + CRC32(<name>) % 900`, then api=base, frontend=base+1, storybook=base+2,
  observability=base+3. Compute it once and write it into
  `justfile`/`docker-compose.yml`. Never hardcode conventional defaults, never
  auto-pick.
- `9999` is reserved for `port-dash`. Every repo needs a
  `.registered-ports.toml` at its root; that is how port-dash discovers services.
  One line per service that has its own port:

  ```toml
  <service_name>         = <port_number>
  <another_service_name> = <another_port_number>
  ```

- New project:
  `uv run python -c "import zlib; print(9000 + zlib.crc32(b'<project>') % 900)"`.
  Add a preflight that fails loudly if the port is held (print pid and cmdline).
  Do not pick a fallback; fix the conflict.
- Dev servers run in named cowork panes (`<project>-<service>`). List the panes
  and reuse one before spawning a new pane.

## Pages

- If `$PAGES_URL` is set (worker207, streaming-server), anything better shown
  than told (comparisons, charts, reports, diagrams) goes in a single
  self-contained HTML file in `/srv/pages`, then give me the link
  `$PAGES_URL/<file>.html`.
- Keep the chat answer short and point to the page. Do not repeat its content.
