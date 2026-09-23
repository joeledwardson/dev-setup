---
title: "BlueBubbles read-receipt repair — 23 September 2026"
---

# BlueBubbles read-receipt repair

All times are Europe/London (BST), 23 September 2026. This is the operational log for the investigation and repair. Credentials, message bodies, contact identifiers, and raw network payloads are excluded.

## Status

- The live Pi registration is corrected and Synapse is running.
- Passive observation on the Pi confirmed read receipts going to the Mac bridge, with successful responses.
- The encrypted source registration is corrected in this checkout; credentials and all nine encryption recipients are preserved.
- Persistent Nix deployment completed at **14:12:50** as system generation **38**, with agenix generation **5**. The corrected registration is now part of the system profile.
- Final checks passed: Synapse active/running, no failed systemd units, correct registration ownership/mode, corrected generation in boot configuration, and a fresh startup record confirming `supports_ephemeral: True`.
- User verification is pending: open a fresh unread iMessage chat in iamb and confirm that it becomes read in Apple Messages.
- No SSH session, diagnostic API request, or configuration change was made on the Mac. The Pi's existing bridge traffic was observed on the Pi only.

## Diagnosis and evidence

The deployed appservice registration contained:

```yaml
receive_ephemeral: true
```

Synapse 1.153.0 ignores that key. Its registration parser requires:

```yaml
de.sorunome.msc2409.push_ephemeral: true
```

This was checked against the actual installed Synapse source and the [matching upstream parser](https://github.com/element-hq/synapse/blob/v1.153.0/synapse/config/appservice.py). Running that parser on the original and corrected registration produced `supports_ephemeral=False` and `supports_ephemeral=True`, respectively.

Before the fix, Synapse accepted an iamb `m.read` receipt at 14:00:23 with HTTP 200, without a corresponding transaction to the iMessage bridge. Ordinary message transactions to that bridge succeeded. This explains why message transport worked while read state did not propagate from Matrix to iMessage.

The bridge also gates sending read receipts on BlueBubbles Private API availability detected at bridge startup. Its [pinned source](https://github.com/mautrix/imessage/blob/300ba6d0e5566d1f841d42ee1555779a9b6fa4be/imessage/bluebubbles/api.go) was inspected as an alternative cause; Mac-side Private API state has not been independently checked.

## Activity log

### Initial inspection, approximately 13:58–14:04

1. Inspected repository status, recent BlueBubbles commits, the Pi Synapse module, the Mac bridge package/configuration, SSH host definitions, and secret recipient declarations. Working tree was initially clean.
2. Connected to `pi-box` as its configured `claude` user. Confirmed Synapse active, with no failed systemd units. It had last restarted at 12:33:30 after the user's deployment.
3. Read Synapse service metadata, generated homeserver configuration, and recent journal entries. Confirmed the Mac bridge was connecting and successfully bridging messages and remote read markers.
4. Initial `sudo -n` checks required authentication. Subsequent necessary root operations used the configured Pi account credential over SSH stdin; credentials were not printed or stored in this log.
5. Read only the relevant registration, filtering credentials from diagnostic output. It contained the wrong ephemeral-event setting, while the bridge URL and user namespaces were present.
6. Inspected an existing local bridge-source research checkout and verified relevant behavior against the exact upstream revision pinned by this repository. The first guessed upstream filename returned 404; the actual implementation is `imessage/bluebubbles/api.go`.
7. Verified that the installed Synapse parser explicitly reads `de.sorunome.msc2409.push_ephemeral`.

### Prepare and apply the repair, approximately 14:04–14:07

1. Created temporary local helper scripts for encrypted-registration preparation, live application, and observation. They retrieve the configured Pi credential at runtime and do not embed its value.
2. Initial standalone parser checks failed because the Nix Python interpreter did not include Synapse/PyYAML dependencies. Resolved this by using the dependency paths declared by the installed Synapse wrapper. No service changes occurred during these failed checks.
3. Decrypted the repository registration in memory on the Pi using its host key; verified its YAML matched the live registration before changing anything.
4. Replaced only `receive_ephemeral: true` with `de.sorunome.msc2409.push_ephemeral: true`.
5. Validated both versions with the installed Synapse parser, then re-encrypted using all nine recipients from `secrets/secrets.nix`. Verified decryption reproduced the corrected bytes exactly.
6. Updated `secrets/mautrix-imessage-registration.age` in this checkout and added an explanatory comment to `secrets/secrets.nix`. No authentication token, namespace, or bridge URL changed.
7. Saved the original live registration as `/run/agenix.d/4/mautrix-imessage-registration.before-read-receipt-fix`, owned by root with mode `0400`. This is a temporary backup under `/run`, not durable storage.
8. Updated the live `/run/agenix/mautrix-imessage-registration` target while preserving its existing owner and mode.
9. Restarted `matrix-synapse`; it became active at **14:07:16**. Startup logs explicitly showed the iMessage appservice loaded with `supports_ephemeral: True`.
10. Asked the user to open a fresh unread iMessage chat in iamb and check Apple Messages. No synthetic messages or read markers were generated by the agent.

### Verification and deployment preparation, approximately 14:07–14:10

1. Observed existing traffic for 45 seconds on the Pi's `tailscale0` interface, filtered to bridge port 29320. Payloads were processed in memory and only aggregate counts were returned: **5 receipt-bearing payloads, 13 ephemeral-bearing payloads, 13 transaction requests, and 13 HTTP 200 responses**. These counts confirm delivery to the Mac bridge, not that Apple Messages updated its UI.
2. `git diff --check` passed.
3. Evaluated the Pi NixOS configuration successfully. The initial local dry-run listed 587 derivations because the local store lacks the Pi's ARM packages; this was not used as an actual deployment plan.
4. A remote-store dry-run initially lacked the evaluated derivation. Copied the derivation closure to the Pi's Nix store. This added store objects only; it did not activate a system generation.
5. An attempt to compare the old generation's derivation directly found that its `.drv` was absent from the Pi store. The running system itself remained present and healthy.
6. The authoritative dry-run on the Pi showed **seven derivations to build**: Synapse restart triggers and service unit, system units, `/etc`, activation scripts, and the system generation. The only fetch was a 0.1 KiB SSH configuration check. No application-package upgrades were required.
7. Started building that narrow system generation on the Pi. Build and activation results will be appended below.

### Persistent deployment, from 14:10

1. The seven-derivation build completed successfully by 14:11:31. Its output is `/nix/store/fpmmrbr6zw0fkn2bf4sd8c45qixph4dg-nixos-system-pi-box-sd-card-26.05.20260603.6b31628`.
2. Compared the complete old and new runtime closures. Exactly six paths were replaced: the encrypted registration, Synapse service unit, restart-trigger file, system-unit collection, `/etc` collection, and system generation. No application packages changed.
3. Ran `switch-to-configuration dry-activate` as root. It exited successfully and listed only `matrix-synapse.service` for stopping/restarting.
4. Began the persistent deployment: set `/nix/var/nix/profiles/system` to the new generation, then ran its `switch-to-configuration switch`. This also regenerates the agenix secrets from the corrected encrypted source.
5. Activation ran from **14:12:21 to 14:12:50** and succeeded. Both `/run/current-system` and the persistent system profile resolve to the new system. Synapse is active. Agenix regenerated the registration into `/run/agenix.d/5` and removed generation 4.
6. An initial final-check script reached the journal check after successfully validating the registration, service state, and boot configuration. Its journal search timed out after 25 seconds. This was a diagnostic timeout, not an activation failure. Repeated the check using a bounded reverse read of recent journal entries.
7. Final verification passed: Synapse has been active/running since **14:12:50**; systemd reports zero failed units; the regenerated registration parses with `supports_ephemeral=True` and retains mode `0400`, UID/GID `224`; the new generation is present in `/boot/extlinux/extlinux.conf`; and the latest Synapse startup record confirms forwarding is enabled. Agenix removed the temporary plaintext backup with generation 4.
8. `git diff --check` passed after the documentation updates. The only remaining functional check is the user's Apple Messages UI test. No Mac restart is currently requested.

## Files and diagnostic artifacts

Repository changes:

- `secrets/mautrix-imessage-registration.age`: corrected encrypted registration.
- `secrets/secrets.nix`: documents the Synapse registration key.
- This log and a link from the September development log.

Temporary local diagnostic artifacts (not committed; `/tmp` may be cleared):

- `/tmp/fix-imessage-registration.py`
- `/tmp/apply-imessage-registration.py`
- `/tmp/watch-imessage-receipts.py`
- `/tmp/pi-read-receipt-copy.log`
- `/tmp/pi-read-receipt-rebuild-dry-run.log`
- `/tmp/pi-read-receipt-remote-dry-run.log`
- `/tmp/pi-read-receipt-build.log`
- `/tmp/pi-read-receipt-closure-diff.log`
- `/tmp/pi-read-receipt-dry-activate.log`
- `/tmp/deploy-imessage-registration.py`
- `/tmp/pi-read-receipt-activation.log`
- `/tmp/pi-read-receipt-final-checks.log`

No changes have been committed or pushed. No Mac deployment has been attempted.
