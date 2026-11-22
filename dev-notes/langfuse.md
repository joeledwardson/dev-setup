# Langfuse on this setup

Langfuse is a web viewer for coding-agent runs. It does not instrument the Sparky app. Its service and the Claude Code/Codex plugins run on `worker207`. The plugins send selected sessions to the local service through its tailnet HTTPS address.

```text
Sparky repo on worker207 → langfuse-agent → Claude/Codex plugin
                                           → https://worker-langfuse.joels-netflix.com
                                              (worker207, tailnet HTTPS)
```

## What this configuration does

- `worker207` runs Langfuse v4.83.0 with Docker Compose: web, worker, PostgreSQL, ClickHouse, Redis and MinIO. It does not start the optional AI Gateway. The web and MinIO API bind only to loopback. Caddy serves them as `worker-langfuse.joels-netflix.com` and `worker-langfuse-media.joels-netflix.com`, accepting only Tailscale IPv4 or IPv6 peers.
- `secrets/langfuse-server-env.age` contains generated database, cache, object-storage and authentication secrets, plus the first user and project keys. `secrets/langfuse-client-env.age` contains only the project API keys and URL. Both are decryptable by `worker207` and trusted personal hosts; agenix exposes the server file to root and the client file to `claude`. Neither plaintext secret is stored in git or the Nix store.
- The initial login is `admin@langfuse.invalid`; use `sudo` to read `LANGFUSE_INIT_USER_PASSWORD` from `/run/agenix/langfuse-server-env` on `worker207` (the file is root-only). Open sign-up is disabled. The initial organization is `Personal`, the project is `Coding Agents`, and project traces have 30-day retention.
- `langfuse-agent` explicitly starts a traced Codex or Claude Code session from the Sparky repo. Normal agent commands remain untraced. It adds `project`, `feature` and `stage` tags; git, tests and review notes remain in their repos.

## Activation after reviewing this branch

1. Switch the `worker207` NixOS configuration from this branch. The Langfuse service starts automatically. Check `systemctl status langfuse`, then open `https://worker-langfuse.joels-netflix.com` from a tailnet device. The first startup downloads several container images and may take a few minutes.
2. On `worker207`, run `task langfuse:client:install` from `dev-setup`. This installs the official Langfuse Codex and Claude Code plugins. It does not pass credentials on the command line; the wrapper supplies them from agenix. Restart each agent after installation. In Codex, review and trust the plugin's Stop hook in `/hooks` when prompted. Existing hooks are left in place.
3. From `~/sparky-fitness-ui`, start a small test session: `langfuse-agent 001-exercise-history plan codex` or `langfuse-agent 001-exercise-history plan claude`. Send a harmless prompt, then verify the prompt, tool result and session in Langfuse. Codex's latest turn may be finalized on the next Stop hook, so send a second short prompt if the first is missing.
4. Test one parent/child run before using traces as review evidence. The plugins capture new sessions only. If a hook fails, the agent still runs; inspect its local hook log and mark any missing trace as missing.

> The plugins can upload prompts, file content and tool output. The wrapper is the opt-in boundary; use ordinary `codex` or `claude` for work you do not want recorded.

## Maintenance

- Upstream Compose source: [Langfuse v4.83.0](https://github.com/langfuse/langfuse/blob/v4.83.0/docker-compose.yml). Our `services/langfuse/override.yml` narrows the ports and sets tailnet URLs. Review upstream changes before changing the pinned version; run `docker compose config --quiet` with an environment file after each edit, without printing rendered configuration because it contains secrets.
- Docker named volumes hold the databases and objects. **No automatic backup is configured yet.** Back up PostgreSQL, ClickHouse and MinIO together before relying on traces long term. `docker compose down -v` deletes the volumes; plain `stop` does not.
- Langfuse's [Compose guide](https://langfuse.com/self-hosting/deployment/docker-compose) recommends at least 4 cores, 16 GiB RAM and 100 GiB storage for a VM. `worker207` has more headroom than the crowded `streaming-server`, but check actual usage after the trial.
- To pause capture, use ordinary `codex` and `claude`. To stop the service, run `sudo systemctl stop langfuse` on `worker207`. Remove the Nix modules in a later rebuild to remove the service configuration; that does not delete Docker volumes.

Sources: [self-hosted architecture](https://langfuse.com/self-hosting), [headless initialization](https://langfuse.com/self-hosting/administration/headless-initialization), [hardening](https://langfuse.com/self-hosting/configuration/hardening), [Codex integration](https://langfuse.com/integrations/developer-tools/codex), [Claude Code integration](https://langfuse.com/integrations/developer-tools/claude-code).
