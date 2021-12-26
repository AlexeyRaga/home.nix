{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.iterm2;

  shell_integration = pkgs.fetchFromGitHub {
    name = "iterm2-shell-integration";
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "891c1aa5fd8ecfebd953d85c6994f3ee8f0d8f3c";
    sha256 = "sha256-d5RrXxmvNJLGrutu1p2t9Gd6qwFn0uUlOKby5C7oVmc=";
  };
  utilities = builtins.attrNames (builtins.readDir "${shell_integration}/utilities");
  aliases = lib.concatMapStringsSep ";" (x: "alias ${x}='${shell_integration}/utilities/${x}'") utilities;

in
{
  options.darwin.apps.iterm2 = { enable = mkEnableOption "Enable iTerm2 - the best terminal for MacOS"; };

  config = mkIf enabled {
    # Install iTerm2 from Homebrew
    homebrew = {
      taps = [ "homebrew/cask" ];
      casks = [ "iterm2" ];
    };

    # Initialise Shell Integration
    programs.bash.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash"; or true
      ${aliases}
    '';
    programs.fish.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';
  };
}
