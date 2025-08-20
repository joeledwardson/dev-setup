# ~/.config/fish/config.fish

# Prevent recursive loops by only installing Fisher if it is missing
if not functions -q fisher
    echo "Fisher not found. Installing Fisher..."

    # Create the fisher function directory if it doesn't exist
    mkdir -p ~/.config/fish/functions

    # Download and install Fisher, but skip re-sourcing configuration
    curl -sL https://git.io/fisher >~/.config/fish/functions/fisher.fish

    # Stop further execution to avoid recursive reloading
    echo "Fisher installed. Please restart your shell."
    return
end

fish_config theme choose "Dracula Official"

function setup-bw
    if ! command -v jq >/dev/null
        echo "jq not found!"
        return 1

    end

    set current_status "$(bw status | jq -r .status)"
    switch $current_status
        case unauthenticated
            echo "Please log in first"
            bw login
        case locked
            echo "locked, please unlock..."
            export BW_SESSION=$(bw unlock --raw)
        case unlocked
            echo "Already unlocked"
        case '*'
            echo "unknown status $current_status"
            exit 1
    end
end

# Essential tmux aliases
alias ta='tmux attach' # Attach to a session
alias ts='tmux new-session -s' # Start new session with name
alias tl='tmux list-sessions' # List all sessions

# Git alises
alias g='git'
alias ga='git add'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gr='git remote'

# Rest of your Fish configuration goes here
echo "Fish configuration loaded successfully."
