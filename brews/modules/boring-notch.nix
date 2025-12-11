{ config, lib, pkgs, user, ... }:

with lib;

let
  cfg = config.brews.boring-notch;
in
{
  options.brews.boring-notch = { 
    enable = mkEnableOption "Enable The Boring Notch";
    
    enableSneakPeek = mkOption {
      type = types.bool;
      default = false;
      description = "Enable sneak peek feature";
    };

    showMirror = mkOption {
      type = types.bool;
      default = false;
      description = "Show mirror in the notch";
    };

    showBatteryIndicator = mkOption {
      type = types.bool;
      default = false;
      description = "Show battery indicator";
    };

    showBatteryPercentage = mkOption {
      type = types.bool;
      default = false;
      description = "Show battery percentage";
    };

    showPowerStatusIcons = mkOption {
      type = types.bool;
      default = false;
      description = "Show power status icons";
    };

    showPowerStatusNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Show power status notifications";
    };

    showCalendar = mkOption {
      type = types.bool;
      default = true;
      description = "Show calendar in the notch";
    };

    autoRemoveShelfItems = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically remove shelf items";
    };

    copyOnDrag = mkOption {
      type = types.bool;
      default = true;
      description = "Copy items when dragging from shelf";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      taps = [ "theboredteam/boring-notch" ];
      casks = [ "boring-notch" ];
    };
  };


  userConfig = mkIf cfg.enable {

    home.activation.boring-notch = 
      let 
        plist = "${user.home or "~"}/Library/Containers/theboringteam.boringnotch/Data/Library/Preferences/theboringteam.boringnotch.plist";
        
        plistContent = lib.generators.toPlist {} {
          SUEnableAutomaticChecks = true;
          enableSneakPeek = cfg.enableSneakPeek;
          menubarIcon = false;
          firstLaunch = false;
          SUHasLaunchedBefore = true;
          SUAutomaticallyUpdate = true;
          showMirror = cfg.showMirror;
          showBatteryIndicator = cfg.showBatteryIndicator;
          showBatteryPercentage = cfg.showBatteryPercentage;
          showPowerStatusIcons = cfg.showPowerStatusIcons;
          showPowerStatusNotifications = cfg.showPowerStatusNotifications;
          showCalendar = cfg.showCalendar;
          autoRemoveShelfItems = cfg.autoRemoveShelfItems;
          copyOnDrag = cfg.copyOnDrag;
        };
      in
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          $DRY_RUN_CMD /usr/bin/xattr -rd com.apple.quarantine /Applications/BoringNotch.app 2>/dev/null || true


          # Check if plist file exists, if not initialize it
          if [[ ! -f "${plist}" ]]; then
            echo "Launching BoringNotch to create container..."
            $DRY_RUN_CMD /usr/bin/open -a "/Applications/BoringNotch.app"

            [[ -n "$DRY_RUN_CMD" ]] && wait_time=0 || wait_time=10
            end_time=$((SECONDS + wait_time))
            while [[ ! -f "${plist}" ]] && ((SECONDS < end_time)); 
            do 
              sleep 0.2; 
            done

            $DRY_RUN_CMD /usr/bin/osascript -e 'quit app "BoringNotch"' 2>/dev/null || true
          fi

          # Set preferences using defaults (merges with existing settings)
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch SUEnableAutomaticChecks -bool true
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch enableSneakPeek -bool ${boolToString cfg.enableSneakPeek}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch menubarIcon -bool false
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch firstLaunch -bool false
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch SUHasLaunchedBefore -bool true
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch SUAutomaticallyUpdate -bool true
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showMirror -bool ${boolToString cfg.showMirror}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showBatteryIndicator -bool ${boolToString cfg.showBatteryIndicator}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showBatteryPercentage -bool ${boolToString cfg.showBatteryPercentage}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showPowerStatusIcons -bool ${boolToString cfg.showPowerStatusIcons}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showPowerStatusNotifications -bool ${boolToString cfg.showPowerStatusNotifications}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch showCalendar -bool ${boolToString cfg.showCalendar}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch autoRemoveShelfItems -bool ${boolToString cfg.autoRemoveShelfItems}
          $DRY_RUN_CMD /usr/bin/defaults write theboringteam.boringnotch copyOnDrag -bool ${boolToString cfg.copyOnDrag}

          # Add to login items and launch if not already running
          if ! /usr/bin/osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | /usr/bin/grep -q "boringNotch"; then
            echo "Adding boringNotch to login items..."
            $DRY_RUN_CMD /usr/bin/osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/boringNotch.app", hidden:false}' 2>/dev/null || true
          fi

          # Launch the app if not already running
          if ! /usr/bin/pgrep -x "boringNotch" > /dev/null 2>&1; then
            echo "Launching boringNotch..."
            $DRY_RUN_CMD /usr/bin/open -a "/Applications/boringNotch.app"
          fi
        '';
  };

}