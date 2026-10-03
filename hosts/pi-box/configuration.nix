{ pkgs, lib, commonGroups, modulesPath, ... }:

let
  ssh-keys = import ../../secrets/host-keys.nix;
in {
  imports = [
    # build image: nix build .#nixosConfigurations.pi-box.config.system.build.sdImage
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"

    # shared secrets are readable by claude; service secrets stay root-only
    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
  ];

  # USB storage drivers are needed to boot from the SSD
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "usbhid" "usb_storage" "uas" ];

  # use zram instead of the default 32GB swapfile
  swapDevices = lib.mkForce [ ];
  zramSwap.enable = true;

  networking.hostName = "pi-box";
  my.ssh.defaultUser = "claude";
  # home Wi-Fi reserves 192.168.1.250 for TV access

  users.users = {
    claude = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = ssh-keys.allHosts;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # avoid devenv trust warnings
  nix.settings.trusted-users = [ "root" "claude" ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];

  # kitty terminal support for SSH
  environment.systemPackages = [ pkgs.kitty.terminfo ];
}
