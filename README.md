# Development setup
# NixOS Setup
If not using a Nix based OS, need to install NixOS (use `--daemon` as its nice to be able to view and restart it using `systemctl`)
See instructions [here](https://nixos.org/download/)

***TODO***
- gcloud completion
- ctrl g without prefix once in copy mode - ctrl G for previous
- learn zsh nav (not vim)
- tmux/xfce indicator for caps/alt/fn keys 

***Done***
- zsh tmux titles not working (new pane doesn't sync with custom title)
- fzf finder with eza (ls replacement, forgot what its called)
- sort out authentication with gh overwritten by nix
- ignore fnm


```bash
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```
the experimental nix and flakes added (see [docs](https://nixos.wiki/wiki/Flakes))
```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

then the daemon must be restarted 
```bash
sudo systemctl restart nix-daemon
```


and the nixGL channel and default added (for OpenGL apps, dont work with linked nix opengl)
```bash
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper
```

# Git credentials
for gh its as simple as (hopefully this can be absolved into the symlinks in the future)
- gh auth setup-git

for glab apparently this works?:
- git config --global credential.https://gitlab.com.helper '!glab auth git-credential'

no idea how this actually works, but an example of it working from claude is:
```
echo -e "protocol=https\nhost=gitlab.com" | glab auth git-credential get
```

apparently it reads from stdin?

`zshrc` creates a function for cursor, assuming an appimage is in `.local/cursor.AppImage`


# setup AI chat
configuration is version controlled, but API keys are not.

To add API keys (check they exist first, otherwise ignore):

```bash
RUN_SETUP=true
if [ -z "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY is not set"
    echo "Please set OPENAI_API_KEY and try again"
    RUN_SETUP=false
fi

if [ -z "$CLAUDE_API_KEY" ]; then
    echo "CLAUDE_API_KEY is not set"
    echo "Please set CLAUDE_API_KEY and try again"
    RUN_SETUP=false
fi

if [ "$RUN_SETUP" = true ]; then
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> ~/.config/aichat/.env
    echo "CLAUDE_API_KEY=$CLAUDE_API_KEY" >> ~/.config/aichat/.env
fi
```

# Configuration
The `.zshrc` provides a debugging variable which uses `zprof` to log the load times when specified.

To use it, set:
```bash
export ZSH_DEBUGRC=true
```

# summary of custom keybindings

Window Management (Super + key):
- `Super + m` - Maximize window
- `Super + Up/Down/Left/Right` - Tile window in that direction
- `Super + u` - Tile window up-left
- `Super + i` - Tile window up-right
- `Super + j` - Tile window down-left
- `Super + k` - Tile window down-right

Moving Windows Between Monitors (Super + Shift + key):
- `Super + Shift + Up/Down/Left/Right` - Move window to monitor in that direction

Applications:
- `Super + l` - Lock screen
- `Super + v` - Show CopyQ (clipboard manager)
- `Super + x` - App finder
- `Super + e` - Open Thunar (file manager)
- `Super + r` - App finder (collapsed)
- `Shift + Super + s` - Screenshot (region select)
- `Ctrl + Alt + t` - Open Ghostty terminal

Window Switching:
- `Alt + grave` (backtick) - Switch windows
- `Alt + Tab` - Cycle windows
- `Alt + Shift + Tab` - Cycle windows (reverse)


# xfce-config-helper
install xfce config helper
```bash
git clone https://github.com/felipec/xfce-config-helper.git && \
cd xfce-config-helper && \
gem install ruby-dbus && \
make install && \
cd .. && \
rm -rf xfce-config-helper
```

# 60% keyboard notes
what keys will i miss in a 60% keyboard?

up/down/left/right
- solution: caps and jkl;

fn keys
- solution: fn and numbres?

surface pro key has alt, fn and windows on left of space bar
- solution: right cmd not that useful. win useful, alt useful fn useful, ctrl manatory
(could) have fn to right, but i dont like that very much
(could) map caps to fn key, then everything else is still accessible?
also up/down/left/right from jkl; are v acessible

home, end, insert, delete, page up. pade down
- fn u/o for page up/down are easy with caps as fn
- fn plus easy for insert with caps
- fn backspace not so bad 
- could just use fn(caps) h/e for home end

# Non nix packages
These packages require openGL or GPU stuff and i can't find an (easy) workaround yet on home manager, simpler just to install via `dnf`,`apt` whatever OS PC is running on 
- kitty
- ulauncher

# Trying to get my head round disk management terminal tools
PARTITIONING TOOLS (modify disks):
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  fdisk (1991) ──same tool──> cfdisk (1994)              │
│      │              │            │                      │
│      │              │            │ (menu interface)     │
│      │              │            │                      │
│      └──────────────┴────────────┘                      │
│                     │                                   │
│                     ↓ replaced by                       │
│                                                         │
│                parted (1999)                            │
│                (modern standard)                        │
│                                                         │
└─────────────────────────────────────────────────────────┘

INFORMATION TOOLS (read-only):
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  lsblk (2010)                 findmnt (2010)            │
│  (block devices)              (mount points)            │
│                                                         │
└─────────────────────────────────────────────────────────┘

Show file systems with mount points
```
lsblk -f
```

example output:
```
NAME        FSTYPE FSVER LABEL         UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
nvme1n1
├─nvme1n1p1 vfat   FAT32 SYSTEM        BE05-F38D                             119.1M    53% /boot
├─nvme1n1p2
├─nvme1n1p3 ntfs         Windows       5466065066063372
├─nvme1n1p4 ntfs         WinRE         F88E06A38E065A90
└─nvme1n1p5 ntfs         RecoveryImage 7040088F40085DEA
nvme0n1
└─nvme0n1p1 ext4   1.0   NIXROOT       c82fdf13-7c80-4864-92ce-78c06d81043c  863.5G     3% /nix/store
                                                                                           /
```


Find mounts
```
findmnt
```

example output:
```
TARGET                  SOURCE                FSTYPE   OPTIONS
/                       /dev/disk/by-uuid/c82fdf13-7c80-4864-92ce-78c06d81043c
│                                             ext4     rw,relatime
├─/dev                  devtmpfs              devtmpfs rw,nosuid,size=1625640k,nr_inodes=4060220,mode=755
│ ├─/dev/pts            devpts                devpts   rw,nosuid,noexec,relatime,gid=3,mode=620,ptmxmode=
│ ├─/dev/shm            tmpfs                 tmpfs    rw,nosuid,nodev,size=16256392k
│ ├─/dev/hugepages      hugetlbfs             hugetlbf rw,nosuid,nodev,relatime,pagesize=2M
│ └─/dev/mqueue         mqueue                mqueue   rw,nosuid,nodev,noexec,relatime
├─/proc                 proc                  proc     rw,nosuid,nodev,noexec,relatime
├─/run                  tmpfs                 tmpfs    rw,nosuid,nodev,size=8128196k,mode=755
│ ├─/run/keys           ramfs                 ramfs    rw,nosuid,nodev,relatime,mode=750
│ ├─/run/wrappers       tmpfs                 tmpfs    rw,nodev,relatime,size=16256392k,mode=755
│ ├─/run/credentials/systemd-journald.service
│ │                     tmpfs                 tmpfs    ro,nosuid,nodev,noexec,relatime,nosymfollow,size=1
│ └─/run/user/1000      tmpfs                 tmpfs    rw,nosuid,nodev,relatime,size=3251276k,nr_inodes=8
│   └─/run/user/1000/doc
│                       portal                fuse.por rw,nosuid,nodev,relatime,user_id=1000,group_id=100
├─/sys                  sysfs                 sysfs    rw,nosuid,nodev,noexec,relatime
│ ├─/sys/kernel/security
│ │                     securityfs            security rw,nosuid,nodev,noexec,relatime
│ ├─/sys/fs/cgroup      cgroup2               cgroup2  rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_
│ ├─/sys/fs/pstore      pstore                pstore   rw,nosuid,nodev,noexec,relatime
│ ├─/sys/firmware/efi/efivars
│ │                     efivarfs              efivarfs rw,nosuid,nodev,noexec,relatime
│ ├─/sys/fs/bpf         bpf                   bpf      rw,nosuid,nodev,noexec,relatime,mode=700
│ ├─/sys/kernel/tracing tracefs               tracefs  rw,nosuid,nodev,noexec,relatime
│ ├─/sys/kernel/debug   debugfs               debugfs  rw,nosuid,nodev,noexec,relatime
│ ├─/sys/kernel/config  configfs              configfs rw,nosuid,nodev,noexec,relatime
│ └─/sys/fs/fuse/connections
│                       fusectl               fusectl  rw,nosuid,nodev,noexec,relatime
├─/nix/store            /dev/disk/by-uuid/c82fdf13-7c80-4864-92ce-78c06d81043c[/nix/store]
│                                             ext4     ro,nosuid,nodev,relatime
└─/boot                 /dev/nvme1n1p1        vfat     rw,relatime,fmask=0022,dmask=0022,codepage=437,ioc

```

Note that above, `/nix/store` is shown to be mounted to the subdirectory `/nix/store/` of `/dev/disk/by-uuid/c82fdf13-7c80-4864-92ce-78c06d81043c`

This is NOT shown in `lsblk`!
