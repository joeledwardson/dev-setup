# only load mod where specified
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi
# history settings
# Add these near the top of your .zshrc, before loading zinit
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
# History settings
setopt SHARE_HISTORY          # Share history between sessions
setopt INC_APPEND_HISTORY     # Add commands to history immediately
setopt EXTENDED_HISTORY       # Add timestamps to history
setopt HIST_FIND_NO_DUPS     # Don't display duplicates during searches
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicated entries
# other options
setopt interactivecomments

# setup brew (must be before plugins so tmux can load)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# setup nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# added by pipx (https://github.com/pipxproject/pipx)
export PATH="$HOME/.local/bin:$PATH"

# print each path entry on a new line
pretty-path() {
    echo "${1:-$PATH}" | sed "s/:/\n/g"
}

# allow calling "cursor ." from terminal to open cursor AI
function cursor {
  nohup "$HOME/.local/cursor.AppImage" "$@" >/dev/null 2>&1 &
  disown
}

function reload-tmux {
  tmux source-file ~/.tmux.conf
}
function reload-zsh {
  source ~/.zshrc
}

# set pager for psql
export PSQL_PAGER=pspg

# tmux escape chars for `next-prompt` and `previous-prompt`
function preexec() {
  print -Pn '\e]133;A\a'
}
function precmd() {
  print -Pn '\e]133;B\a'
}

# install and load zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"


# Load from cache immediately
autoload -U compinit
compinit

# load pure theme
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure

# Plugins
zinit light Aloxaf/fzf-tab
# Without wait because we want the tools immediately
zinit light z-shell/zsh-navigation-tools
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit ice wait'0' silent
zinit light catppuccin/zsh-syntax-highlighting
zinit light MichaelAquilina/zsh-you-should-use

# Use turbo mode for plugins that don't need immediate loading
# Load git plugin directly (not from Oh-My-Zsh)
zinit ice wait'0' lucid
zinit load davidde/git

# control left/right because im lazy and dont want to un-learn
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# install colours repo
if [ ! -d "/tmp/LS_COLORS" ]; then
  mkdir /tmp/LS_COLORS && curl -L https://api.github.com/repos/trapd00r/LS_COLORS/tarball/master | tar xzf - --directory=/tmp/LS_COLORS --strip=1
  ( cd /tmp/LS_COLORS && make install )
fi
source ~/.local/share/lscolors.sh

# aliases
# stolen from (https://github.com/DarrinTisdale/zsh-aliases-ls)
alias ls='ls --color=auto'
alias l='ls -lFh'          #size,show type,human readable
alias la='ls -lAFh'        #long list,show almost all,show type,human readable
alias lr='ls -tRFh'        #sorted by date,recursive,show type,human readable
alias lt='ls -ltFh'        #long list,sorted by date,show type,human readable
alias ll='ls -l'           #long list
alias ldot='ls -ld .*'
alias lS='ls -1FSsh'
alias lart='ls -1Fcart'
alias lrt='ls -1Fcrt'



if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
