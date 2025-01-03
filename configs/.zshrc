# only load mod where specified
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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

# rust path
export PATH="$HOME/.cargo/bin:$PATH"

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
function copyfile {
    # Resolve the full path of the file
    local fullpath=$(realpath $1)
		if [ ! -e $fullpath ]; then
        echo "Error: Invalid file path" >&2
        return 1
    fi

    # Copy the file path to the clipboard
    echo "file://$fullpath" | xclip -selection clipboard -t text/uri-list
    echo "File path copied to clipboard: $fullpath"
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

# install fzf and setup completion
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ("$HOME/.fzf/install" --all)
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

# Load from cache immediately
autoload -U compinit
compinit

# Load powerlevel10k theme
zinit ice depth"1" # git clone depth
zinit light romkatv/powerlevel10k

# Plugins
#zinit light Aloxaf/fzf-tab
# Without wait because we want the tools immediately
zinit light z-shell/zsh-navigation-tools
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

zinit ice wait'0' silent
zinit light catppuccin/zsh-syntax-highlighting
zinit ice wait'0' silent
zinit light MichaelAquilina/zsh-you-should-use
zinit ice wait'0' silent
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::vi-mode
zinit ice wait'0' silent
zinit light xPMo/zsh-ls-colors
# Use turbo mode for plugins that don't need immediate loading
# Load git plugin directly (not from Oh-My-Zsh)
zinit ice wait'0' lucid
zinit load davidde/git


# Check if fnm exists before trying to evaluate it
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# control left/right because im lazy and dont want to un-learn
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

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
alias lf='find "$PWD" -maxdepth 1' # show full path
# stolen from OMZ tmux plugin
# Essential tmux aliases
alias ta='tmux attach'     # Attach to a session
alias tad='tmux attach -d -t' # Attach to session in detached mode
alias ts='tmux new-session -s' # Start new session with name
alias tl='tmux list-sessions' # List all sessions
alias tksv='tmux kill-server' # Kill the tmux server
alias tkss='tmux kill-session -t' # Kill a specific session
# nixGL for kitty
alias kitty='nixGL kitty'
alias kitten='nixGL kitten'

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi


