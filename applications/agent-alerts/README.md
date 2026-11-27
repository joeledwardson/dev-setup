# Agent alerts

Schedule agent runs through RunWisp. RunWisp handles timing, run history and
ntfy failure notifications. A small script interprets the agent's structured
output and prints markers that RunWisp's output-pattern matching catches.

```toml
# Each task that needs alerting adds these two lines:
notify = ["phone"]
failures = ["+output:NEW_FINDING", "+output:AGENT_REPORTED_ERROR"]
```

- `NEW_FINDING` → published as a failure notification via ntfy
- `AGENT_REPORTED_ERROR` → also published via ntfy
- Agent startup errors, timeouts and host failures → RunWisp's native ntfy

Add a new monitor by creating a prompt in `jobs/` and a matching task in
`runwisp.toml`. Test it with `./run-agent-monitor <name> --force`.

The runner uses OpenCode with `ollama-cloud/deepseek-v4.1-flash` and the key at
`/run/agenix/ollama-api-key`; override the model with `AGENT_ALERTS_MODEL`.
OpenCode has no JSON Schema enforcement, so the prompt carries the schema and
the final message is rejected unless it parses as `{"notices": [...]}`.

## Monitors

| Task | When | Question |
|---|---|---|
| `lotr` | Sun 09:00 | future Lord of the Rings concerts at the Royal Albert Hall |
| `zed-keyboard-prompts` | Mon 07:30 | can dialogs and "install this extension?" prompts be answered by keyboard |
| `zed-extension-install` | Mon 07:40 | can extensions and ACP agents be installed without a mouse |
| `zed-remote-sessions` | Mon 07:50 | do agent threads survive a disconnect and follow the user between machines |
| `zed-web-client` | Mon 08:00 | is there a browser-hosted Zed |

The Zed jobs read GitHub through `gh`, which is authenticated as
`joels-claude-bot` under `/home/claude` on worker207, so they need no token of
their own. Each job sets `AGENT_ALERTS_STATE_DIR` to its own directory: findings
are deduplicated by `id`, and a shared directory would let one job suppress
another job's report of the same release.
