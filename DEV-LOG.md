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
