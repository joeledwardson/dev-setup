# Development setup
Before anything can be run, ansible must be installed

# install pipx and ansible
```bash
# install pipx: https://github.com/pypa/pipx?tab=readme-ov-file#on-linux
sudo apt update
sudo apt install pipx
pipx ensurepath
sudo pipx ensurepath --global # optional to allow pipx actions with --global argument

# install ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
pipx install --include-deps ansible
```

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
