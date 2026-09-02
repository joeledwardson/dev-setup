# PLACEHOLDER — overwrite this with the real thing before installing.
#
# Run `sudo nixos-generate-config --root /mnt` on worker207 (README step 10)
# and copy /mnt/etc/nixos/hardware-configuration.nix over this file. The values
# below are guessed from `lsblk -f` on the existing Ubuntu install; the root
# UUID in particular WILL change once you mkfs the partition.
{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # nvme0n1p2 — reformat as ext4, then swap in the new UUID
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/376206f9-1246-499a-8d40-a066b079b3fd";
    fsType = "ext4";
  };

  # nvme0n1p1 — the existing 1G ESP, reused as-is (Ubuntu had it at /boot/efi)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DC30-D79E";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
