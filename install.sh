#!/bin/bash

# Fail immediately if a command exits with a non-zero status
set -e

# Aliases
DOTFILES_DIR="$HOME/dotfiles"

clone_dotfiles_repo() {
    echo "Cloning dotfiles repository..."

    # Clone if it doesn't already exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        git clone --bare https://github.com/lambergmiki/dotfiles.git "$DOTFILES_DIR"
    else
        echo "Dotfiles repo already cloned. Skipping clone step..."
    fi

    # Checkout with force to overwrite existing files
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME checkout -f

    # Hide untracked files
    git --git-dir=$DOTFILES_DIR --work-tree=$HOME config status.showUntrackedFiles no

    echo "Dotfiles repository cloned and checked out."
}


install_oh_my_posh() {
    echo "Installing Oh My Posh..."
    if [ ! -d "$HOME/.cache/oh-my-posh" ]; then
        curl -s https://ohmyposh.dev/install.sh | bash -s
    else
        echo "Oh My Posh is already installed. Skipping installation..."
    fi

    # Define directories for themes
    local theme_dir="$HOME/.cache/oh-my-posh/themes"
    local theme_file="$theme_dir/dracula.omp.json"

    # Install dracula theme
    echo "Installing Dracula theme..."
    if [ ! -d "$theme_dir" ]; then
	# make full path incl. parent directories
        mkdir -p  "$theme_dir"
        curl -fsS https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/dracula.omp.json -o "$theme_file"
    else
        echo "Dracula theme is already installed. Skipping installation..."
    fi
}


# Install and set up Visual Studio Code
setup_vs_code() {

    # Install VS Code, or skip entire process if already installed
    if command -v code &>/dev/null; then
        echo "VS Code is already installed. Skipping installation..."
    else
        echo "Installing VS Code…"

        # Install prerequisites
        sudo apt-get install -y wget gpg apt-transport-https

        # Add Microsoft keyring directory if missing
        sudo mkdir -p /etc/apt/keyrings

        # Only import the key if it isn't already on the disk
        if ! grep -q "packages.microsoft.com" /etc/apt/keyrings/packages.microsoft.gpg 2>/dev/null; then
            echo "Adding Microsoft GPG key…"
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
                | gpg --dearmor \
                | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
        else
            echo "Microsoft GPG key already present—skipping."
        fi

        # Only add the repo if it’s missing or mis‑configured
        REPO_LINE="deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
        if ! grep -Fxq "$REPO_LINE" /etc/apt/sources.list.d/vscode.list 2>/dev/null; then
            echo "Adding VS Code repo…"
            echo "$REPO_LINE" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        else
            echo "VS Code repository already configured—skipping."
        fi

        # Finally update & install
        sudo apt update
        sudo apt install -y code
    fi

    # Download extensions with extensions list provided
    if command -v code &>/dev/null; then
        echo "Installing extensions for VS Code…"
        if [ -f "$HOME/.vscode/extensions_list.txt" ]; then
            xargs -a "$HOME/.vscode/extensions_list.txt" -n1 code --install-extension
        else
            echo "No extensions_list.txt found at \$HOME/.vscode/"
        fi
    else
        echo "VS Code installed, but 'code' CLI not found. Restart your shell and run extension install manually."
    fi
}


# Main
clone_dotfiles_repo
install_oh_my_posh
setup_vs_code

echo "All installations and configurations are complete!"
