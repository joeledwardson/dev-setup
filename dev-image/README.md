# Minimal dev shell

Build with `task dev:build`, then use `task dev:container`. The image keeps the
shared shell, terminal and core Neovim setup; language toolchains
can be installed for the project that needs them.

| Use | Packages |
| --- | --- |
| Shell and plugins | zsh, sheldon |
| `l`, `ll`, `la`, `lx`, `lT`, `lr`, completion previews | eza |
| Fuzzy completion, history and search | fzf, fd, ripgrep |
| Git and aliases, `lg` | git, git-delta, lazygit, openssh |
| Reading files and help | bat, less, man-db, file |
| Terminal multiplexer | tmux |
| JSON helpers and downloads | jq, curl |

Neovim 0.12.5 is installed from the official x86-64 release archive and checked
against a pinned SHA-256. Update both `NVIM_VERSION` and `NVIM_SHA256` when
changing releases. Docker copies the whole `configs/nvim/lua/core/` directory
alongside `init_core.lua`, renamed to `init.lua`, and installs its plugins with
`nvim -l`. The desktop pack lockfile is not copied.

No Python/pip, Node/npm, PostgreSQL libraries, GCC/make, uv, standalone Vim,
fastfetch, wget, unzip, net-tools or socat are explicitly installed. The
container's `vim` and `nvimc` aliases both run Neovim core.

Desktop helpers for GUI clipboard access, Bitwarden and LLM tools still require
their respective programs if invoked; they are not needed for shell startup.
