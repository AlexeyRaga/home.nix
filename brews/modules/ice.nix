{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.ice;
in 
{
  options.brews.ice = {
    enable = mkEnableOption "Enable Ice - menu bar manager for MacOS";

    launchAtLogin = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Launch Ice at login.";
    };

    autoUpdate = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic updates for Ice.";
    };

    showOnHover = mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show hidden menu bar items on hover.";
    };

    hideApplicationMenus = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hide application menus when Ice is active.";
    };

    showAllSectionsOnUserDrag = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show all menu bar sections when user drags an item.";
    };

    enableAlwaysHiddenSection = mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the always-hidden section in the menu bar.";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "jordanbaird-ice" ];
    };
  };

  userConfig = mkIf cfg.enable {
    targets.darwin.defaults = {
      "com.jordanbaird.Ice" = {
        SUEnableAutomaticChecks = cfg.autoUpdate;
        SUAutomaticallyUpdate = cfg.autoUpdate;
        showOnHover = cfg.showOnHover;
        HideApplicationMenus = cfg.hideApplicationMenus;
        ShowAllSectionsOnUserDrag = cfg.showAllSectionsOnUserDrag;
        EnableAlwaysHiddenSection = cfg.enableAlwaysHiddenSection;
      };
    };

    home.activation.configureIce = ''
      # Only add to login items if not already present
      if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/Ice.app"; then
        $DRY_RUN_CMD /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Ice.app\", hidden:false}"
        $DRY_RUN_CMD /usr/bin/osascript -e 'tell application "Ice" to launch'
      fi
    '';
  };
}
