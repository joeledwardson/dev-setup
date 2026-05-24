## Contents

- [Development setup](#development-setup)
  - [Utility script](#utility-script)
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

> Reference notes, dev log and cheat sheets have moved to the **[docs site](https://joels-claude-bot.github.io/dev-setup/)**.

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

## Utility script
I have included a utility script `util` to select between
- `os`: building the OS configuration
    1. Builds NixOS configuration
    2. Installs Yazi plugin packages
- `dotfiles`: applying the dotfiles symlinks
    1. Runs common dotfile symlinks
    2. Symlinks hyprland host specific `custom.conf` if exists
- `clean`: delete old NixOS generations

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
13. Remove the USB and reboot, (GRUB should appear) and pick NixOS to boot into


## NixOS setup
I have tried to keep my NixOS setup as simple as possible, in a vain attempt to avoid millions of different helper files, sub-modules and overrides.

For configuration files I am using `dotbot`, thus I believe `home-manager` just adds another layer of un-necessary complexity and have opted to not us it

The basic structure follows nix flakes:
- `flake.nix` selects between the configuration of the machine (located in `hosts`)
- `flake.lock` tracks the exact commit of `nixpkgs` so package versions can be replicated
- `modules` provides re-usable configuration fragments
> something I did not know as a beginner is the difference between a NixOS module and configuration fragment, which are distinct!


## Dotfiles
My dotfiles are located in `configs`, where the symlinks are applied by `dotbot` via the `install.conf.yaml` configuration file

Some of the configurations are built from scratch, some based off a templated, or edited from the defaults:
- `nvim` for neovim is based off the neovim kickstart project (although it has diverged a fair bit since)
- `hyprland` is based off the default generated configuration, although has diverged a fair bit since then
> To see the diffs from my config to the example generated one, run `git diff --no-index  <(curl https://raw.githubusercontent.com/hyprwm/Hyprland/refs/heads/main/example/hyprland.conf) configs/hypr/hyprland.conf`
- `waybar` shamelessy stolen from https://github.com/d00m1k/SimpleBlueColorWaybar
- `swaync` shamelessy stolen from https://github.com/schererleander/hyprdots

## Windows installation
(Yes i know, windows.....)

But we all have to use it sometimes. So i'm minimizing the pain with 2 windows specific additions to the utility `util` with
- `sh util winpush`
- `sh util winpull`
(it's a bash script so need to run it with `sh` from busybox on windows)

But firstly, for the initial setup, need to install scoop and clone the repo

> Command to install scoop [was copied from here](https://scoop.sh/)
```cmd
echo "installing scoop....."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
echo "done installing scoop!"
echo ""

echo "installing git..."
winget install -e --id Git.Git

echo "getting repo...."
git clone https://github.com/joeledwardson/dev-setup.git

echo "running package installers..."
cd dev-setup && bash util winpull
```


## Applications
The `applications` directory is symlinked via `dotbot` to my "custom" directory in `~/.local/share/applications/`.

This enables me to have custom entries available in fuzzel launcher

Ok this is pretty confusing.

Well at least i found the docs for the `mimeapps.list` file: [here](https://specifications.freedesktop.org/mime-apps/latest/file.html)

God... linux docs. well here is the list:
- [base directory specification](https://specifications.freedesktop.org/basedir/latest/)
- [desktop file naming](https://specifications.freedesktop.org/desktop-entry/latest/file-naming.html), explains about the applications subdirectory

Ok well it turns out brave browser has this line in its config!

## Wallpapers
Wallpapers shameless stolen from [mylinuxforwork dotfiles repo](https://github.com/mylinuxforwork/dotfiles/tree/main)

## Keyboard re-bindings
I have a set of keyboard bindings I apply as I find it helps my workflow. In short
- `caps` is rebound to a combination of `ctrl` and `escape` (hold vs tap)
- `space` when in used in conjunction with another key actives a special layer

For keyboard devices such as my laptop keyboard which do not support QMK, I have used `keyd` to remap keys (see `modules/nixos-keyd.nix`).

For my programming keybaords that do support QMK, I have forked [QMK firmware here](https://github.com/joeledwardson/qmk_firmware) with layers added for my keyboards

## Git authentication
I have setup `glab` and `gh `clis for authentication so that i can login via browser on each which is easier

TODO: review SSH keys synchronisation without commiting to git? maybe syncthing?

## Secrets
###  Syncthing
So Am keeping my secrets in syncthing which requires peer to peer connection to operate

> Would be interesting to read into, how it pierces NAT?

According to [this documentation](https://forum.syncthing.net/t/device-behind-nat-is-sometimes-connected-without-relays/15684/7) there are some ways that it pierces NAT but honestly this is a whole tpoic in itself...

I have enabled it in NixOS so (should) be available from http://localhost:8384/

Can see the files to my `Sync` folder (requires root)
```bash
sudo ls -la /var/lib/syncthing/Sync
```

### Work VPN setup
I have put my work VPN in syncthing which can be imported by network manager as a ovpn configuration file.

> UPDATE FEBRUARY 2026 - password is now based on jumpcloud! and user is JoelEdwardson

Script below imports 
```bash
if [[ -z "$VPN_PATH" ]]; then
  echo "no VPN_PATH found"
else if [[ -z "$VPN_PASS" ]]; then
  echo "no password provided"
else
  nmcli c import type openvpn file "$VPN_PATH"
  nmcli c modify work vpn.user-name JoelEdwardson
  nmcli c modify work vpn.secrets "password=$VPN_PASS"
  nmcli c modify work +vpn.data "password-flags=0"
  nmcli c modify work ipv4.dns "8.8.8.8 1.1.1.1"
  nmcli c modify work ipv4.ignore-auto-dns no
fi
```

> According to claude, we have to forcifully set the dns otherwise it does not work? - have added claudes notes in ./DEV-LOG.md

