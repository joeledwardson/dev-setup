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
