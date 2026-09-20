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
  ];

  # Work with existing Windows partitions during installs and recovery.
  boot.supportedFilesystems = [ "ntfs" ];

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "uk";

  services.openssh.enable = true;
  environment.variables.EDITOR = "vim";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Install and edit the target system.
    disko
    git
    vim
    curl
    parted

    # Inspect hardware, files, processes, and networking.
    file
    ripgrep
    jq
    lsof
    pciutils
    usbutils
    dmidecode
    dig
    htop
    tmux
  ];

  system.stateVersion = "25.05";

  # Disable the CD installer module's default wpa_supplicant service.
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
    extraGroups = [ "wheel" ];
    initialPassword = "password";
  };

  users.users.claude = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    initialPassword = "password";
  };

  # Pre-baked gitconfig — avoids the `git config --global` dance
  # before committing the new host's hardware-configuration.nix.
  environment.etc."gitconfig".text = ''
    [user]
      name  = Joel
      email = joel.edwardson1@gmail.com
  '';
}
