# Dev Log — SparkyFitness declarative deploy on pi-box

Tracking the unattended push to get SparkyFitness running on pi-box, fully declarative,
with agenix secrets, and an end-to-end test (localhost + Tailscale HTTPS).

## 2026-06-21 — Start: agenix secrets + rebuild + e2e

**Context**: `hosts/pi-box/sparkyfitness.nix` already drives the upstream compose via a systemd
service (clone-if-missing + `docker compose up` foreground) plus a foreground `tailscale serve`
unit. Outstanding: the `.env` was a manual file. Goal = make secrets declarative via agenix
(already used elsewhere in this flake), rebuild, and verify e2e.

**Plan**:
1. agenix: register `secrets/sparkyfitness-secrets.age` (the 4 real secrets only), wire the
   agenix module into pi-box, decrypt at runtime, pass to compose via `--env-file`.
2. Non-secret config (DB name/user, data paths, FRONTEND_URL) → declarative Nix `environment`.
3. `nix eval` → `nixos-rebuild switch --flake .#pi-box`.
4. Verify: `docker ps` (3 up), `curl localhost:3004`, then `tailscale serve` + HTTPS e2e.

**Env facts**: docker active (29.5.2); pi-box on tailnet as `pi-box.rove-lydian.ts.net`; no serve
config yet; sudo works with the default password; ntfy token not present on this host (skip
push notifications, log instead).

## 2026-06-21 — Deployed + e2e GREEN

**Action**: Wired agenix secrets, rebuilt pi-box twice, drove the stack up.

**Bug fixed**: first rebuild → `sparkyfitness.service` failed `ExecStartPre` with `200/CHDIR`.
systemd applies `WorkingDirectory` before `ExecStartPre`, and `.../repo/docker` doesn't exist
until the clone runs. Fix: `WorkingDirectory` = the always-present StateDirectory
(`/var/lib/sparkyfitness`); reference the compose file by absolute path (`-f ${composeDir}/...`)
with a stable `-p sparkyfitness` project name.

**Result (e2e green)**:
- agenix secret decrypts to `/run/agenix/sparkyfitness-secrets` (root-only); compose reads it via `--env-file`.
- 3 containers healthy: db, server (migrations applied, Better Auth mounted, listening :3010,
  `/api/health` 200), frontend.
- `http://localhost:3004` → 200, `<title>SparkyFitness</title>`.
- `https://pi-box.rove-lydian.ts.net` → 200, valid TLS cert (curl ssl_verify=0), `/api/health` 200.
- `tailscale serve status` shows "No serve config" — expected: the serve is foreground (held by
  the systemd unit), not persisted to disk. Stopping the unit removes it. Matches the intent.

**Not yet tested**: reboot survival (units are enabled + `wantedBy multi-user.target`, but I did
not reboot the box unattended). First account still needs registering via the UI.

## 2026-06-21 — Review pass + re-verify

Ran a focused code review (proportionate to a 91-line, e2e-verified Nix diff). 3 findings, all
fixed in commit "address review findings": stale Podman comment, clone-wedge on interrupted first
clone (added `rm -rf` guard), and DRY for the data paths. Rebuilt (3rd switch) → stack restarted,
re-verified: localhost:3004 / https root / https /api/health all 200, valid TLS, login page
(with passkey button) renders. DONE — on branch `sparkyfitness-pi-box-deploy`, not merged.

## 2026-06-22 — Declarative AI (Gemini) + MCP sidecar correction

**Goal**: set up SparkyAI declaratively. Two findings while proving the mechanism:

1. **Global AI config is seedable with NO user/admin/session.** `ai_service_settings` allows
   `user_id=NULL` for `is_public=TRUE` rows (CHECK constraint enforces it), inserted via a system
   client that bypasses RLS, and `getActiveAiServiceSetting` falls back to the global row (Priority
   2). Proved end-to-end: decrypted the existing `llm-gemini-key.age`, ran the app's own
   `upsertGlobalAiServiceSetting` via `docker exec ... tsx` inside the server container → global
   Gemini (gemini-2.5-flash) inserted, encrypted with the app's cipher. The frontend's
   `GET /api/chat/ai-service-settings` resolver returns it for the test user. Idempotent (upsert by
   service_type).

2. **MCP sidecar must come back (correction).** Chat on the published `codewithcj/*:latest` images
   FAILS with `Connection closed` — the image's `chatService` uses MCP **stdio** transport (spawns
   `/app/SparkyFitnessMCP/dist/index.cjs`, absent in the server image) UNLESS
   `SPARKY_FITNESS_MCP_URL` is set, and this image has no in-process `/mcp` route. `main`'s compose
   marks MCP deprecated/in-process, but the RELEASE hasn't caught up. So: re-add the
   `sparkyfitness-mcp` sidecar + point the server at it over HTTP — matches the proven
   streaming-server config. Doing this via a NixOS-managed `docker-compose.override.yml`.

## 2026-06-22 — AI e2e GREEN

Rebuilt with the MCP sidecar override + AI-seed unit. Results:
- Override rendered to /etc/sparkyfitness/docker-compose.override.yml; server got
  `SPARKY_FITNESS_MCP_URL=http://sparkyfitness-mcp:3001`; mcp container serving HTTP on 3001
  (its docker healthcheck reports "unhealthy" but it's functionally up — cosmetic).
- `sparkyfitness-ai-seed.service` → "updated global gemini" (idempotent: found the existing
  global google row and updated it). 4 containers running.
- Chat e2e: `POST /api/chat/stream` → Gemini streamed "PONG" (finishReason stop, 200).
- Agentic e2e: "what did I log today?" → Gemini called MCP tool `sparky_manage_food`
  (tool-input → tool-output) and answered correctly (empty — the test sandwich was the 21st).

So SparkyAI (Gemini + MCP tools + DB) is fully working and fully declarative: agenix key →
app-native encryption → global is_public AI row → chat falls back to it for every user. Cosmetic
TODO: mcp healthcheck shows unhealthy; functionally fine.
