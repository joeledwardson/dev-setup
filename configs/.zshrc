# only load mod where specified
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# setup brew (must be before plugins so tmux can load)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# lazy load nvm
nvm() {
  echo "🚨 NVM not loaded! Loading now..."
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  nvm "$@"
}

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# added by pipx (https://github.com/pipxproject/pipx)
export PATH="$HOME/.local/bin:$PATH"

# print each path entry on a new line
pretty-path() {
    echo $PATH | sed "s/:/\n/g"
}

# Disable shared history between sessions
unsetopt SHARE_HISTORY       

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

# load pure theme
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure

# Plugins
zinit light Aloxaf/fzf-tab

# Use turbo mode for plugins that don't need immediate loading
zinit ice wait'0' silent
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'0' silent
zinit light zsh-users/zsh-syntax-highlighting

# Load git plugin directly (not from Oh-My-Zsh)
zinit ice wait'0' lucid
zinit load davidde/git

# Load additional functionality
zinit light zsh-users/zsh-completions
zinit light zdharma-continuum/fast-syntax-highlighting

# Adjust the suggestion delay in milliseconds (default is 0.15 seconds)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# Load from cache immediately
autoload -Uz compinit
compinit -C

# Check for new completions in background
{
  # Compile new completion files
  for dump in ~/.zcompdump(N.mh+0); do
    compinit
    touch ~/.zcompdump
  done
} &!

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
