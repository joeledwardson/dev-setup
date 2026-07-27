# SCAFFOLD — XMPP + Slidge stack, runs PARALLEL to matrix.nix (ADR-011 "Reviewing alternatives").
# Nothing here removes the Matrix cut; this is the "try XMPP + Slidge" evaluation rig.
#
# Why it looks like this:
#  - Prosody is the XMPP server (services.prosody, first-class in nixpkgs).
#  - The 4 Slidge gateways are NOT in nixpkgs (see ADR-011 upstream table), so they're
#    packaged inline as Python apps below. Their HEAVY runtime deps (signal-cli for Signal,
#    the go toolchain for WhatsApp's whatsmeow, python itself) are cache.nixos.org hits on
#    aarch64 — verified by dry-run, see ADR. Only the thin Python plugin code + whatsmeow Go
#    source build locally (seconds / modest RAM). (Telegram uses pyrofork — pure python,
#    NOT tdlib as first assumed.)
#  - Each gateway connects to Prosody as an XMPP *external component* on localhost:5347.
#  - profanity is the terminal client.
#
# ⚠️ TODO before this evaluates:
#   1. Real `version` + `hash` for each pname (run `nix build`, paste the hash it prints;
#      lib.fakeHash forces the mismatch error that reveals the correct one).
#   2. Verify each plugin's Python `dependencies` list against its pyproject.toml.
#   3. Component shared secrets via agenix (placeholders below) — Prosody config is Lua and
#      can't envsubst, so the secret is rendered into the store here. Acceptable for a
#      tailnet-only, single-user box; revisit if that changes.
{ pkgs, config, lib, ... }:

let
  serverName = "jollof.chat";
  fqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
  py = pkgs.python3Packages;

  # ⚠️ EVERYTHING from here down to `mkGatewayService` is DEFINED BUT NOT YET WIRED into the
  # config below. Nix evaluates let-bindings lazily, so because the body no longer references
  # these, they are never built and the missing-dep placeholders never error. This is the
  # parked gateway work (real versions/hashes preserved for the follow-up). The ACTIVE config
  # right now is just Prosody + profanity.

  # --- LEAF DEPS MISSING FROM NIXPKGS (confirmed 2026-07-22) — each needs its own derivation ---
  #   thumbhash            (slidge core — BLOCKS ALL gateways)   pure python
  #   pyrofork             (slidgram)                            pure python (MTProto)
  #   slidge-style-parser  (slidgram)                            pure python
  #   rlottie-python       (slidgram [lottie] extra)             python + bundled rlottie
  #   linkpreview          (slidge-whatsapp)                     pure python
  #   mautrix-facebook     (messlidger)                          pure python
  # The `py.<name>` references to these below are PLACEHOLDERS and will fail eval until the
  # derivations exist. Package thumbhash first — nothing builds without it.

  # --- slidge core ---
  # ⚠️ The four gateways DON'T agree on a slidge version — they span three major lines:
  #     slidgram/slidgnal need 0.4.x, slidge-whatsapp needs 0.3.x, messlidger needs 0.2.x.
  # That's impossible in one Python venv, but fine in Nix: each gateway below carries its
  # OWN isolated closure, so we build three slidge versions and hand each gateway the right
  # one. Drop all this once nixpkgs PR #541886 lands and the plugins catch up to one version.
  #
  # Versions + hashes below are REAL (confirmed against PyPI 2026-07-22). Build backend and
  # the exact dep set still want a `nix build` pass to confirm — see TODOs.
  mkSlidge = { version, hash, extraDeps ? [ ] }:
    py.buildPythonPackage {
      pname = "slidge";
      inherit version;
      pyproject = true;
      src = pkgs.fetchPypi { pname = "slidge"; inherit version hash; };
      build-system = [ py.hatchling ]; # TODO confirm backend from pyproject
      # from PyPI requires_dist. NOTE: several of these may not yet be in nixpkgs
      # (thumbhash, rlottie-python) and would each need their own small derivation.
      dependencies = (with py; [
        aiohttp alembic configargparse defusedxml pillow python-magic qrcode slixmpp sqlalchemy
      ]) ++ extraDeps;
      doCheck = false;
    };
  slidge_0_4_1 = mkSlidge {
    version = "0.4.1";
    hash = "sha256-zkdWC5akn+uOo3Ufevsee+uwuPs0kBW7iTzUy2FsnsM=";
    extraDeps = [ py.thumbhash ]; # + rlottie-python for the [lottie] extra slidgram wants — TODO
  };
  slidge_0_3_11 = mkSlidge {
    version = "0.3.11";
    hash = "sha256-gurBPkbw4qDwZiv8BwPCJYAOHvpj3ntQKUTDS4SDuQY=";
    extraDeps = [ py.thumbhash ];
  };
  slidge_0_2_12 = mkSlidge {
    version = "0.2.12";
    hash = "sha256-ZKH704+lt5oRkxptDjOLzER+OVziJ1sgwmMSvLVDctE=";
    extraDeps = [ py.thumbhash ];
  };

  # Each gateway pins the slidge version it declares, plus its own extra deps.
  #   slidge      = the matching slidge core built above
  #   extraDeps   = python deps from the gateway's own requires_dist
  #   nativeExtras = non-python programs the gateway shells out to at runtime (added to PATH)
  mkGateway = { pname, version, hash, slidge, extraDeps ? [ ], nativeExtras ? [ ] }:
    py.buildPythonApplication {
      inherit pname version;
      pyproject = true;
      src = pkgs.fetchPypi { inherit pname version hash; };
      build-system = [ py.hatchling ]; # TODO confirm backend
      dependencies = [ slidge ] ++ extraDeps;
      makeWrapperArgs =
        lib.optional (nativeExtras != [ ]) "--prefix PATH : ${lib.makeBinPath nativeExtras}";
      doCheck = false;
    };

  # Telegram — needs slidge 0.4.1. Uses pyrofork (pure-python MTProto), NOT tdlib.
  # pyrofork + slidge-style-parser are NOT in nixpkgs yet → each needs its own derivation (TODO).
  slidgram = mkGateway {
    pname = "slidgram"; version = "0.4.0";
    hash = "sha256-NdbR94ZV+fL2/ofWa5Grt3oLvBw5b7Y3Qr4bA1U7SWQ=";
    slidge = slidge_0_4_1;
    extraDeps = [ py.pyrofork /* TODO package */ ]; # + slidge-style-parser (TODO package)
  };
  # Signal — needs slidge 0.4.1 (beta line) + signal-cli on PATH at runtime (nixpkgs, JVM).
  slidgnal = mkGateway {
    pname = "slidgnal"; version = "0.4.0b1";
    hash = "sha256-d4xuh2/PdbLlRKuwjcskbgQXMIk8KE/ELqPm4pt9kKM=";
    slidge = slidge_0_4_1;
    nativeExtras = [ pkgs.signal-cli ];
  };
  # WhatsApp — needs slidge 0.3.x. Embeds a whatsmeow Go component: the real build needs a
  # buildGoModule sub-derivation for the shared lib, then wired in. + linkpreview (py).
  slidge-whatsapp = mkGateway {
    pname = "slidge-whatsapp"; version = "0.3.11";
    hash = "sha256-tNqspXxvza4GKgd07FGGhjrmyKxtH3JvL3itVcYjsx0=";
    slidge = slidge_0_3_11;
    extraDeps = [ py.linkpreview ]; # TODO Go/whatsmeow component
  };
  # Facebook/Meta — STALE: pinned to slidge 0.2.x, ~2 majors behind the rest. Depends on
  # mautrix-facebook. Weakest link; consider dropping if it fights the build.
  messlidger = mkGateway {
    pname = "messlidger"; version = "0.2.1";
    hash = "sha256-fOj7NOdtd+k7dx5Zyzr8z3MX7/JVdAP1/nzDakapqUU=";
    slidge = slidge_0_2_12;
    extraDeps = [ py.mautrix /* mautrix-facebook — TODO confirm attr */ ];
  };

  componentPort = 5347;
  # TODO agenix: one shared secret per component, matched on both sides. Placeholder value.
  componentSecret = "CHANGEME-agenix";

  # ---- HELPER 1: one Prosody "Component" block (Lua text) for a gateway ----
  # `name` is the subdomain, e.g. "whatsapp" -> Component "whatsapp.jollof.chat".
  # Returns a plain string; we concatenate several of these into prosody's extraConfig.
  mkComponent = name: ''
    Component "${name}.${serverName}"
        component_secret = "${componentSecret}"
  '';

  # ---- HELPER 2: one systemd service definition (an attrset) for a gateway ----
  # Takes the three things that differ per gateway; returns the value you assign to
  # `systemd.services.slidge-<name>`. Everything shared (restart policy, sandboxing,
  # ordering) is defined ONCE here instead of repeated four times.
  #   name   = subdomain / instance label, e.g. "whatsapp"
  #   pkg    = the built gateway package (its /bin/slidge is the entrypoint)
  #   module = the Slidge plugin's python module name, e.g. "slidge_whatsapp"
  mkGatewayService = { name, pkg, module }: {
    description = "Slidge gateway: ${name}";
    after = [ "prosody.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "slidge-${name}";
      ExecStart = lib.concatStringsSep " " [
        "${pkg}/bin/slidge"
        "--legacy-module=${module}"
        "--server=127.0.0.1"
        "--jid=${name}.${serverName}"
        "--secret=${componentSecret}" # TODO from agenix (EnvironmentFile + $VAR)
        "--home-dir=/var/lib/slidge-${name}"
      ];
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
in {
  # ---- terminal clients ----
  # profanity = polished daily driver; poezio = fuller XEP coverage (ad-hoc commands /
  # service discovery) for driving slidge gateway registration. Both hit the same account.
  environment.systemPackages = [ pkgs.profanity pkgs.poezio ];

  # ---- XMPP server ----
  services.prosody = {
    enable = true;
    admins = [ "jollof@${serverName}" ];
    # single-user, 1:1-only eval box: we don't run a MUC (group-chat) domain or HTTP
    # file-sharing, so opt out of the XEP-0423 compliance assertion the module enforces.
    xmppComplianceSuite = false;
    # the sync story from the ADR: MAM = server-side history, carbons = multi-device fan-out.
    modules = {
      mam = true;      # XEP-0313 history on the server
      carbons = true;  # XEP-0280 fan messages to all logged-in resources
      # privilege (XEP-0356, "act as me") is a COMMUNITY module — needs a package override and
      # is only useful once the gateways exist. Re-add it alongside the gateways.
    };
    virtualHosts."${serverName}" = {
      enabled = true;
      domain = serverName;
    };
    # `jollof.chat` is a fake tailnet-only domain → no ACME cert, and wiring a self-signed
    # cert into the module is a faff. The tailnet ALREADY encrypts transport, so for this
    # eval box we allow unencrypted c2s auth instead of fighting XMPP-layer TLS.
    # ⚠️ test-only: if this server is ever exposed beyond the tailnet, add real certs and
    #    delete these two lines.
    extraConfig = ''
      c2s_require_encryption = false
      allow_unencrypted_plain_auth = true

      -- Slidge gateways dial in here as XMPP external components (localhost only).
      component_ports = { 5347 }
      component_interface = "127.0.0.1"

      -- Signal gateway (slidgnal). This secret MUST match slidgnal's --secret arg.
      -- ⚠️ test-only plaintext secret in the nix store; move to agenix before real use.
      Component "signal.${serverName}"
          component_secret = "testsecret-signal"
    '';
  };

  # ---- Slidge gateways: PARKED ----
  # The 4 gateway packages + mkGatewayService are defined in `let` above with real
  # versions/hashes, but are NOT wired here yet — they need leaf packages missing from
  # nixpkgs (thumbhash, pyrofork, linkpreview, mautrix-facebook, slidge-style-parser).
  # Packaging those is the follow-up. When ready, add e.g.:
  #   systemd.services.slidge-signal =
  #     mkGatewayService { name = "signal"; pkg = slidgnal; module = "slidgnal"; };

  # ---- expose XMPP c2s over the tailnet (same pattern as matrix-tailscale-serve) ----
  # NOTE: XMPP c2s is :5222 (STARTTLS), not HTTP — `tailscale serve` is HTTP-oriented, so
  # this likely means binding prosody's c2s to the tailnet interface directly rather than
  # proxying. TODO decide: direct bind vs tailscale tcp-forward. Left out until chosen.

  # ---- secrets (TODO) ----
  # age.secrets.xmpp-component-secret.file = ../../secrets/xmpp-component-secret.age;
}
