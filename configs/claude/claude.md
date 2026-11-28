# Claude Code

@../agents/AGENTS.md

## Permissions

- Preserve my sanity: before asking permission to read files outside the
  directory, or to run anything at all, check whether the action is already
  allowed (fetch and the rest of the allow list are). You may fetch freely.
- Exception: if `IS_SANDBOX_MACHINE:1` is set, run whatever you like.
- Prefer the Read / Glob / Grep tools, which are permitted, over `awk`/`sed`.
- Do not pipe bash commands where a direct command works. A pipe drops the
  pre-approved `Find:*` / `Grep:*` permissions.
