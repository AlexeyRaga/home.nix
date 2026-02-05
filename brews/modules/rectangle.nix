{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.rectangle;
  convertShortcuts = shortcuts: builtins.mapAttrs (_: lib.shortcuts.convertShortcut) shortcuts;
in 
{
  options.brews.rectangle = {
    enable = mkEnableOption "Enable Rectangle - window manager for MacOS";

    shortcuts = mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Rectangle keyboard shortcuts. Accepts multiple formats:
        - String: "ctrl+option+n"
        - Attrset: { key = "n"; modifiers = ["ctrl" "option"]; }
        - Pre-formatted: { keyCode = 45; modifierFlags = 786432; }
      '';
      example = {
        maximize = "option+cmd+return";
        reflowTodo = { key = "n"; modifiers = ["ctrl" "option"]; };
        toggleTodo = lib.shortcuts.mkShortcut { key = "b"; modifiers = ["ctrl" "option"]; };
      };
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

    launchOnLogin = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Launch Rectangle automatically on login.";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "rectangle" ];
    };
  };

  userConfig = mkIf cfg.enable {

    targets.darwin.defaults = {
      "com.knollsoft.Rectangle" = {
          SUEnableAutomaticChecks = cfg.autoUpdate;
          moveCursorAcrossDisplays = cfg.moveCursorAcrossDisplays;
          gapSize = cfg.gapBetweenWindowsPx;
          launchOnLogin = cfg.launchOnLogin;
        } // convertShortcuts cfg.shortcuts;
      };

    home.activation = mkIf cfg.launchOnLogin {
      configureRectangle = ''
        # Only add to login items if not already present
        if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/Rectangle.app"; then
          $DRY_RUN_CMD /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Rectangle.app\", hidden:false}"
          $DRY_RUN_CMD /usr/bin/osascript -e 'tell application "Rectangle" to launch'
        fi
      '';
    };
  };
}
