# Hermes agent service, bundled for per-host import.
#
# Pulls in the upstream hermes-agent flake module, enables the service, and
# wires it to the `hermes-env` agenix secret. The service creates the `hermes`
# group; users get it via commonGroups (see flake.nix) so the interactive
# `hermes` CLI can read the service's shared HERMES_HOME (/var/lib/hermes/.hermes
# — config.yaml is 0660 hermes:hermes).
#
# Requires the host to also import modules/nixos-secrets.nix (provides
# age.secrets."hermes-env").

{ inputs, config, ... }:

{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  services.hermes-agent = {
    enable = true;
    settings.model = "google/gemini-3-flash";
    environmentFiles = [ config.age.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };
}
