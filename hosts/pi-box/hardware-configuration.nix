# TODO: replace with nixos-generate-config --show-hardware-config
{ ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat"; };
}
