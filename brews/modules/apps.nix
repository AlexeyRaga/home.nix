{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.brews.apps;

in
{
  options.brews.apps = {

    casks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of casks to install via Homebrew.";
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew packages to install.";
    };

    macApps = mkOption {
      type = types.attrsOf types.ints.positive;
      default = { };
      description = "List of macOS applications to install via Homebrew.";
    };
  };

  systemConfig = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = false;
      };
      casks = cfg.casks;
      brews = cfg.brews;
      masApps = cfg.macApps;
    };
  };

}

