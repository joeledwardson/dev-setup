## Contents

- [Development setup](#development-setup) [Utility script](#utility-script)
  - [Adding a new device](#adding-a-new-devices)
  - [NixOS setup](#nixos-setup)
  - [Dotfiles](#dotfiles)
  - [Windows installation](#windows-installation)
  - [Applications](#applications)
  - [Wallpapers](#wallpapers)
  - [Keyboard re-bindings](#keyboard-re-bindings)
  - [Git authentication](#git-authentication)
  - [Secrets](#secrets)
    - [Syncthing](#syncthing)
    - [Work VPN setup](#work-vpn-setup)

> Reference notes, dev log and cheat sheets have moved to the **[docs site](https://joeledwardson.github.io/dev-setup/)**.

# Development setup
This repository covers my development setup, including
- NixOS configuration files 
- dotfiles to manage my configurations
- some development notes

Thus, the above (almost) fully describes my system state from OS to packages to configuration.

Given I am always tinkering with dotfiles and configurations, using NixOS or even home-manager is not responsive enough, having to "rebuild" every time a single change is made, so I use `dotbot` with symlinks.

> For example, adding a single line in `zshrc` would require a full `sudo nixos-rebuild switch` via NixOS or `home-manager build` with home-manager to apply the `zshrc` changes. With symlinks, I simple save the changes and open a new shell.

The downsides are:
- my configuration is not truly re-producible. Dotfiles are managed separately, symlinks might break, stale links might not get cleaned up
- the upside is a any changes can be applied immediately once symlinkes are established

I have made a sincere attempt to keep this repository as un-cluttered and simple as possible.

I found most dotfiles repositories daunting, with large complex configurations split into multiple sub-modules.
> Whilst this is fine if you understand fully, I do not believe it is a good starting point as the learning process of achieving such a configuration isas important as the result


## Adding a new devices
I have found that to add a new devices it's easiest to add the initial code for the device on an existing setup **before** cloning the repository. This is because, otherwise NixOS requires the files to be added to git, which in turn requires git's stupid global username and email 😠. All of this is before the nix packages have been installed and `dotbot` run to setup symlinks to git config...

Thus (from an existing machine with git configured):
1. Create a new directory in `hosts` with the apprioriate hostname, by copying the most similar existing one
2. Go into the `configuration.nix` of the new host and update the `hostname`
3. Make any other necessary changes to `configuration.nix` in the new device (mounts, nvidia, cuda etc)
4. Delete the contents of `hardware-configuration.nix` (NOT the file itself!) to make space for the new correct configuration
5. Add a mapping from the username@hostname to the configuration in the `hosts` directory in `flake.nix`
6. Commit and push the changes

Then, on the target device:

7. Use my nixos live usb installer - should clone this repo `dev-setup` and setup jollof/claude users 

Then, back to main device, SSH (should) be installed so either via firewall or the device itself - grab itts IP and SSH in

8. Resize the windows partition (if there is one), and create a new `ext4` partition for NixOS. Or... define artitions declaratively using `disko`
> I used GParted because I'm lazy and it handles resizing NTFS windows file system and creates the `ext4` FS for me
9. if not using disko (its command mounts), Mount the partitions (in my example p7 is my new nix partition, and p1 is EFI)
```bash
sudo mount /dev/nvme0n1p7 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot
```
10. Generate the hardware configuration
```bash
sudo nixos-generate-config --root /mnt
```
10. Set a hostname for convenience later scripts (hostname wont be set yet until nix is built)
```bash
export NEW_HOSTNAME=<....>
```
11. Copy it into my hosts dir
```bash
cp /mnt/etc/nixos/hardware-configuration.nix "$HOME/dev-setup/hosts/$NEW_HOSTNAME/hardware-configuration.nix"
```
12. Then, can install from the flake in the dev-setup dir (hostname wont be set yet so have to specify it)
```bash
sudo nixos-install --root /mnt --flake .#$NEW_HOSTNAME
```
13. Copy any changes to the new partition so they don't get lost
```bash
cd ~/dev-setup
git diff > sudo tee /mnt/home/dev-setup-changes/patch >/dev/null

```
14. Remove the USB and reboot, (GRUB should appear) and pick NixOS to boot into. then apply the changes
```bash
cd ~/dev-setup
git apply /mnt/home/dev-setup-changes.patch
```

## New device authentication

tailscale
```bash
sudo tailsacle up --auth-key <auth_key_here>
```

login to github auth with classic API key
```bash
gh auth login
```

login to gitlab, and add the SSH key
```bash
glab auth login
glab ssh-key add ~/.ssh/id_ed25519.pub --title $(hostname)
```



## Dotfiles
My dotfiles are located in `configs`, where the symlinks are applied by `dotbot` via the `install.conf.yaml` configuration file

Some of the configurations are built from scratch, some based off a templated, or edited from the defaults:
- `waybar` shamelessy stolen from https://github.com/d00m1k/SimpleBlueColorWaybar
- `swaync` shamelessy stolen from https://github.com/schererleander/hyprdots

## Wallpapers
Wallpapers shameless stolen from [mylinuxforwork dotfiles repo](https://github.com/mylinuxforwork/dotfiles/tree/main)

## Keyboard re-bindings
I have a set of keyboard bindings I apply as I find it helps my workflow. In short
- `caps` is rebound to a combination of `ctrl` and `escape` (hold vs tap)
- `space` when in used in conjunction with another key actives a special layer

For keyboard devices such as my laptop keyboard which do not support QMK, I have used `keyd` to remap keys (see `modules/nixos-keyd.nix`).

For my programming keybaords that do support QMK, I have forked [QMK firmware here](https://github.com/joeledwardson/qmk_firmware) with layers added for my keyboards


