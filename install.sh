#!/usr/bin/env bash

{ # Prevent script running if partially downloaded

set -euo pipefail

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'

header() {
  printf "${CYAN}%s${NOCOLOR}\n" "$@"
}

info() {
  printf "${GREEN}%s${NOCOLOR}\n" "$@"
}

warn() {
  printf "${ORANGE}%s${NOCOLOR}\n" "$@"
}

error() {
  printf "${RED}%s${NOCOLOR}\n" "$@"
}

# Lifted from https://github.com/kalbasit/shabka/blob/8f6ba74a9670cc3aad384abb53698f9d4cea9233/os-specific/darwin/setup.sh#L22
sudo_prompt() {
  echo
  header "We are going to check if you have 'sudo' permissions."
  echo "Please enter your password for sudo authentication"
  sudo -k
  sudo echo "sudo authenticaion successful!"
  while true ; do sudo -n true ; sleep 60 ; kill -0 "$$" || exit ; done 2>/dev/null &
}

install_nix() {
  echo
  header "Installing Nix"
  command -v nix >/dev/null || {
    warn "'Nix' is not installed. Installing..."
    # printf responses based on:
    #    - Would you like to see a more detailed list of what we will do? n
    #    - Can we use sudo? y
    #    - Ready to continue? y
    printf "n\ny\ny" | sh <(curl -fsSL https://nixos.org/nix/install) --daemon
    # Update local shell
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  }
  info "'Nix' is installed! Here is what we have:"
  nix-shell -p nix-info --run "nix-info -m"
}

install_nix_darwin() {
  echo
  header "Installing Nix on macOS..."
  command -v darwin-rebuild >/dev/null || {
    warn "'nix-darwin' is not installed. Installing..."
    nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer --out-link /tmp/nix-darwin

    # nix-darwin controls nix.conf
    sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.backup-before-nix-darwin

    # printf based on:
    #   - Would you like to edit the configuration.nix before starting? n
    #   - Would you like to manage <darwin> with nix-channel? y
    #   - Would you like to load Darwin configuration in /etc/bashrc? y
    #   - Would you like to load Darwin configuration in /etc/zshrc? y
    #   - Would you like to create /run? y
    printf "n\ny\ny\ny\ny" | /tmp/nix-darwin/bin/darwin-installer
  }
  info "'nix-darwin' is installed!"
}

install_home_manager() {
  echo
  header "Installing Home Manager"
  if [[ ! $( nix-channel --list | grep home-manager ) ]]; then
    warn "Adding 'home-manager' Nix channel..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
  fi
  info "Home Manager channel is installed. Here are available channels:"
  nix-channel --list
}

install_homebrew() {
  echo
  header "Installing Homebrew"
  command -v brew >/dev/null || {
    warn "'Homebrew' is not installed. Installing..."
    printf "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  info "'Homebrew' is installed! Here is what we have:"
  brew --version
  # echo "Making sure that 'Homebrew' is healthy..."
  # brew doctor
}

clone_repository() {
  echo
  repository="AlexeyRaga/home.nix"
  header "Setting up the configuration from github.com:${repository}..."
  clone_target="${HOME}/.nixpkgs"
  if [[ ! $( cat "${clone_target}/.git/config" | grep "github.com" | grep "${repository}" ) ]]; then
    if [ -d "${clone_target}" ]; then
      warn "Looks like '${clone_target}' exists and it is not what we want. Backing up as '${clone_target}.backup-before-clone'..."
      echo mv "${clone_target}" "${clone_target}.backup-before-clone"
    fi
    warn "Cloning 'github.com:${repository}' into '${clone_target}'..."
    git clone "https://github.com/${repository}.git" "${clone_target}"
  fi

  info "'${clone_target}' is sourced from github.com:'${repository}'."
  cd "${clone_target}"
  git remote -v
  cd - >/dev/null
}

darwin_build() {
  echo
  header "Setting up 'darwin' configuration..."
  for filename in shells bashrc zshrc; do
    filepath="/etc/${filename}"
    if [ -f "${filepath}" ] && [ ! -L "${filepath}" ]; then
      warn "Backing up '${filepath}' as '${filepath}.backup-before-nix-darwin'..."
      sudo mv "${filepath}" "${filepath}.backup-before-nix-darwin"
    fi
  done

  echo
  info "All done and ready"
  echo "Now you can edit the configuration in '$HOME/.nixpkgs'".
  echo
  echo "When you finish tuning the configuration, please re-enter your shell and call:"
  echo
  echo "> darwin-rebuild switch"
  echo
}

# Run the installation workflow
sudo_prompt
install_nix
install_home_manager
install_homebrew
install_nix_darwin
clone_repository
darwin_build

# # Clean dock settings of applications
# defaults write com.apple.dock persistent-apps -array
# defaults write com.apple.dock recent-apps -array
# killall Dock

} # Prevent script running if partially downloaded
