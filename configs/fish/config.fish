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

function bw-setup
    if ! command -v jq >/dev/null
        echo "jq not found!"
        return 1

    end

    set current_status "$(bw status | jq -r .status)"

    switch $current_status
        case unauthenticated
            echo "Please log in first with 'bw login' before setting up session"
            return 1
        case locked
            echo "locked, please unlock..."
            set unlock_result (bw unlock --raw)
            if test $status -ne 0
                echo "Failed to unlock!"
                return 1
            end
            set -gx BW_SESSION $unlock_result
        case unlocked
            echo "Already unlocked"
        case '*'
            echo "unknown status $current_status"
            return 1
    end
end

function bw-view
    # get all items from bitwarden
    set bw_items $(bw list items)

    # pass ID (hidden as 1st col) to fzf with details
    set selected_id $(echo $bw_items | jq -r '.[] | .id + " " + .name + " " + .login.username' | fzf --with-nth 2.. | awk '{print $1}')

    # check user selected an item
    if test -z $selected_id
        echo "no item selected!"
        exit 1
    end

    # filter items based on selected ID and convert to yaml
    echo $bw_items | jq -r ".[] | select(.id == \"$selected_id\")" | yq -p=json
end

function bw-edit
    # get all items from bitwarden
    set bw_items $(bw list items)

    if test -z bw_items
        return 1
    end

    # pass ID (hidden as 1st col) to fzf with details
    set selected_id $(echo $bw_items | jq -r '.[] | .id + " " + .name + " " + .login.username' | fzf --with-nth 2.. | awk '{print $1}')

    # check user selected an item
    if test -z $selected_id
        echo "no item selected!"
        return 1
    end
    echo "retrieved ID $selected_id"

    # create temp file
    set tmpfile (mktemp)

    # write JSON to temp file
    echo $bw_items | jq -r ".[] | select(.id == \"$selected_id\")" >$tmpfile

    # check file not empty
    if test -z "$(cat -A $tmpfile)"
        echo "error, json is empty!"
        return 1
    end

    # open in editor (this blocks until editor closes)
    $EDITOR $tmpfile

    if test "$(cat $tmpfile)" = "$item_json"
        echo "no changes made, exiting..."
        rm -f $tmpfile
        return 0
    end

    # update bitwarden with edited JSON
    echo "sending updated JSON to bitwarden..."
    cat $tmpfile | bw encode | bw edit item $selected_id

    # cleanup
    rm -f $tmpfile

    echo "Item $selected_id updated successfully"
end

# copy a file to clipboard
function copyfile
    set localpath "$argv[1]"

    # Resolve the full path of the file
    set fullpath (realpath "$localpath")
    if test ! -e "$fullpath"
        echo "Error: Invalid file path" >&2
        return 1
    end

    # Copy the file path to the clipboard
    echo "file://$fullpath" | wl-copy -t text/uri-list
    echo "File path copied to clipboard: $fullpath"
end

# Essential tmux aliases
alias ta='tmux attach' # Attach to a session
alias ts='tmux new-session -s' # Start new session with name
alias tl='tmux list-sessions' # List all sessions

# Git alises
alias g='git'
alias lg='lazygit'
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
