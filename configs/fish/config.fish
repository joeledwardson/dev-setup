# ~/.config/fish/config.fish

# Prevent recursive loops by only installing Fisher if it is missing
if not functions -q fisher
    echo "Fisher not found. Installing Fisher..."

    # Create the fisher function directory if it doesn't exist
    mkdir -p ~/.config/fish/functions

    # Download and install Fisher, but skip re-sourcing configuration
    curl -sL https://git.io/fisher > ~/.config/fish/functions/fisher.fish

    # Stop further execution to avoid recursive reloading
    echo "Fisher installed. Please restart your shell."
    return
end

fish_config theme choose "Dracula Official"

# Rest of your Fish configuration goes here
echo "Fish configuration loaded successfully."

