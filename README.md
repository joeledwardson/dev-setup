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
