{ ... }:

{
  # This is still macOS. nix-darwin only manages the declared settings and
  # services on top of it.
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "joels-mac-mini";

  # Keep Nix builds isolated from the rest of the machine.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Both services are managed as native macOS launchd jobs.
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # Compatibility version for nix-darwin's stateful defaults. Do not change
  # this during routine upgrades.
  system.stateVersion = 6;
}
