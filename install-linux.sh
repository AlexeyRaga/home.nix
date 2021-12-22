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

install_home_manager() {
  echo
  header "Installing Home Manager"
  if [[ ! $( nix-channel --list | grep home-manager ) ]]; then
    warn "Adding 'home-manager' Nix channel..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
  fi

  command -v home-manager >/dev/null || {
    warn "Installing Home Manager..."
    nix-shell '<home-manager>' -A install
  }

  info "Home Manager is installed. Here are available channels:"
  nix-channel --list
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

# Run the installation workflow
sudo_prompt
install_nix
install_home_manager
# clone_repository

# # Clean dock settings of applications
# defaults write com.apple.dock persistent-apps -array
# defaults write com.apple.dock recent-apps -array
# killall Dock

} # Prevent script running if partially downloaded
