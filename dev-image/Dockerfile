# Layered on top of the nix-built `dev-image-base` (see flake.nix).
# Base provides: all headless dev tools (pinned via nixpkgs 25.11), zsh, cacert,
# /etc/passwd, XDG + ZDOTDIR env, /bin/<tool> symlinks, claude-code.
#
# This stage handles the imperative bootstrap: cloning in the dev-setup repo,
# running dotbot, seeding nvim plugins/LSPs, generating an ssh key.
# Build via: task dev:build   (or see Taskfile.yml for the three steps).

FROM dev-image-base:latest

# bring the repo contents in. dotbot symlinks from here.
COPY . /root/dev-setup
WORKDIR /root/dev-setup

RUN git submodule update --init \
 && dotbot -c install.conf.yaml \
 && sheldon lock \
 && nvim --headless "+Lazy! sync" +qa \
 && nvim --headless "+MasonToolsInstallSync" +qa \
 && ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -q

# dont run initial prompt for login, see https://tessl.io/blog/configuring-claude-code/
COPY ./dev-image/claude.json /root/.claude.json

# claude yolo alias + welcome message
COPY ./dev-image/zshrclocal /root/.config/zshrclocal

WORKDIR /root
CMD ["/bin/zsh"]
