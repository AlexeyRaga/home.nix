{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.rectangle;
in 
{
  options.brews.rectangle = {
    enable = mkEnableOption "Enable Rectangle - window manager for MacOS";

    commands = mkOption {
      type = lib.types.listOf command;
      default = [];
      description = "List of commands for Rectangle.";
    };

    moveCursorAcrossDisplays = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Move cursor across displays when moving windows.";
    };

    gapBetweenWindowsPx = mkOption {
      type = lib.types.int;
      default = 0;
      description = "Gap size between windows in pixels.";
    };

    autoUpdate = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic updates for Rectangle.";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "rectangle" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.activation.configureRectangle = ''
      # Only add to login items if not already present
      if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/Rectangle.app"; then
        $DRY_RUN_CMD /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Rectangle.app\", hidden:false}"
        $DRY_RUN_CMD /usr/bin/osascript -e 'tell application "Rectangle" to launch'
      fi

      $DRY_RUN_CMD /usr/bin/defaults write com.knollsoft.Rectangle SUEnableAutomaticChecks -bool ${boolToString cfg.autoUpdate}
      $DRY_RUN_CMD /usr/bin/defaults write com.knollsoft.Rectangle moveCursorAcrossDisplays -bool ${boolToString cfg.moveCursorAcrossDisplays}
      $DRY_RUN_CMD /usr/bin/defaults write com.knollsoft.Rectangle gapSize -int ${toString cfg.gapBetweenWindowsPx}
    '';
  };
}