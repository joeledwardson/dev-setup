# Custom NixOS live installer ISO.
#
# Build:
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
#
# Burn (find /dev/sdX with `lsblk`):
#   sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
{ pkgs, modulesPath, lib, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../../modules/nixos-minimal.nix
  ];

  # The CD installer module enables wpa_supplicant by default;
  # NetworkManager (from nixos-minimal) handles wifi instead.
  networking.wireless.enable = false;

  # No point firewalling a live USB.
  networking.firewall.enable = false;

  # NM causes namespace failures on squashfs. Use dhcpcd instead — brings up
  # all interfaces and writes DNS to /etc/resolv.conf with zero fuss.
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP               = lib.mkForce true;

  # Include all non-free firmware — live USB needs to work on any hardware.
  hardware.enableAllFirmware = true;

  # Drop straight to a shell without typing anything.
  services.getty.autologinUser = lib.mkForce "jollof";

  users.users.jollof = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "password";
  };

  users.users.claude = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "password";
  };

  # Pre-baked gitconfig — avoids the `git config --global` dance
  # before committing the new host's hardware-configuration.nix.
  environment.etc."gitconfig".text = ''
    [user]
      name  = Joel
      email = joel.edwardson@whiteswandata.com
  '';

  # Clone dev-setup automatically once network is up so the repo
  # is ready to use without any manual steps.
  systemd.services.bootstrap-devsetup-jollof = {
    description = "Clone dev-setup repo into jollof home";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jollof";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -d /home/jollof/dev-setup ]; then
        ${pkgs.git}/bin/git clone https://github.com/joeledwardson/dev-setup.git /home/jollof/dev-setup
      fi
      cd /home/jollof/dev-setup
      ${pkgs.git}/bin/git submodule update --init
      ${pkgs.dotbot}/bin/dotbot -c install.conf.yaml
      ${pkgs.sheldon}/bin/sheldon lock
    '';
  };

  systemd.services.bootstrap-devsetup-claude = {
    description = "Clone dev-setup repo into claude home";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "claude";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -d /home/claude/dev-setup ]; then
        ${pkgs.git}/bin/git clone https://github.com/joeledwardson/dev-setup.git /home/claude/dev-setup
      fi
      cd /home/claude/dev-setup
      ${pkgs.git}/bin/git submodule update --init
      ${pkgs.dotbot}/bin/dotbot -c install.conf.yaml
      ${pkgs.sheldon}/bin/sheldon lock
    '';
  };
}
