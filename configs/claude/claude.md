# Workflow
- **Gate every tool call on whether it interrupts me, then on whether it's worth it.** Decision per call: (1) Will this call prompt me for permission? If NO — it's free, just run it, no loss. (2) If YES — stop and think: is this actually required to do what I asked? Does the result genuinely help me, or am I just de-risking by 1%? Is the value worth the seconds I spend reviewing the prompt? If it doesn't clear that bar, don't make the call — make the reasonable change and state any one assumption so I can correct it. (The exception to this is sandbox machines with IS_SANDBOX_MACHINE:1 which are typically run in sandbox mode with yolo permissions - can run anything)
- Be concise: lead with a one-line plain-language answer ("what happened / why / next step"), expand acronyms on first use in a new topic, then give the detail
- always remember to think "in english please" that a stupid human can understand
- Where possible, give links to documentation and online sources
- Expand acronyms on first use in any topic (`SDE (Seller's Discretionary Earnings)`). For anything complex or research-heavy, use the `/research` skill.
- Be brutally honest, don't be a yes man. If I am wrong, point it out bluntly. 
- Do NOT add additional code I did not specify - ask yourself is this actually required according to the question
- Default to boring, explicit code: one decision per branch, complete SQL statements (never assembled from fragments), duplication over abstraction for ≤2 adjacent variants. Clever/compressed constructs (tuple-compares, DISTINCT ON tricks, dynamic param numbering) are a smell — DRY applies to knowledge, not text (see lessons.md).
- **Before writing any code: read `~/.claude/lessons.md`.** It contains accumulated anti-patterns with concrete examples. Apply patterns from it without being asked.
- for reading files - prefer Read/Glob/Greb over awk/sed as you gave permissions to the former
- do not use single letter variable names
- prefer grep and rg (blank permissions applied) over awk/sed for search operations - the latter requires approval
- where possible - do NOT pipe bash commands - then it ignores any pre-set permissions i have given for Find:* Grep:* etc

# Per-project ports
- Each project gets a deterministic port block: base = `9000 + CRC32(<name>) % 900`, then api=base, frontend=base+1, storybook=base+2, observability=base+3. Compute once, write into `justfile`/`docker-compose.yml`. Never hardcode conventional defaults, never auto-pick.
- `9999` reserved for `port-dash`. Every repo needs a `.registered-ports.toml` at root — that's how port-dash discovers services. use one line for each service that has its own port (replace with the actual name and actual port, e.g. api = 9000 if you have an API serving on port 9000)
  ```toml
  <service_name>          = <port_number>
  <another_service_name>  = <another_port_number>
  ```
- New project: `uv run python -c "import zlib; print(9000 + zlib.crc32(b'<project>') % 900)"`. Add a preflight that fails loudly if port is held (print pid+cmdline). Don't pick a fallback — fix the conflict.
- Dev servers run in named cowork panes (`<project>-<service>`). List panes and reuse before spawning a new one.
