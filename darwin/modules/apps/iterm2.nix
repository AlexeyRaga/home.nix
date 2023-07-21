{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.iterm2;

  shell_integration = pkgs.fetchFromGitHub {
    name = "iterm2-shell-integration";
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "4999d188aba9e470fa921367288ab6d5074b5324";
    sha256 = "sha256-HXmZty8emMoUtyuJpLLY+IfHBIJjG9wUJNGv0a3hJBc=";
  };
  utilities = builtins.attrNames (builtins.readDir "${shell_integration}/utilities");
  aliases = lib.concatMapStringsSep ";" (x: "alias ${x}='${shell_integration}/utilities/${x}'") utilities;

in
{
  options.darwin.apps.iterm2 = {
    enable = mkEnableOption "Enable iTerm2 - the best terminal for MacOS";

    font = mkOption {
      type = types.str;
      default = "FiraCodeNFM-Reg 12";
    };

    columns = mkOption {
      type = types.ints.positive;
      default = 150;
      description = "Terminal window size (horizontal)";
    };

    rows = mkOption {
      type = types.ints.positive;
      default = 40;
      description = "Terminal window size (vertical)";
    };
  };

  config = mkIf enabled {
    # Install iTerm2 from Homebrew
    homebrew = {
      casks = [ "iterm2" ];
    };

    targets.darwin.plists = {
      "Library/Preferences/com.googlecode.iterm2.plist" = {
        "New Bookmarks:0:Normal Font" = cfg.font;
        "New Bookmarks:0:Columns" = toString cfg.columns;
        "New Bookmarks:0:Rows" = toString cfg.rows;
      };
    };

    # Initialise Shell Integration
    programs.bash.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
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
