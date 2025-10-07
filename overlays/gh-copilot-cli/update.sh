#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodejs_22 nix-update

set -euo pipefail

version=$(npm view @github/copilot version)

# Generate updated lock file
cd "$(dirname "${BASH_SOURCE[0]}")"
npm i --package-lock-only @github/copilot@"$version"
rm -f package.json

# Update version and hashes
cd -
nix-update gh-copilot-cli --version "$version"