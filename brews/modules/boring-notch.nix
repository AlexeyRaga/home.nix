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
    # Declarative plist configuration using the new targets.darwin.plists module
    # (Parent directory is automatically created by lib.plists)
    targets.darwin.plists.containers."theboringteam.boringnotch" = {
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

    # Setup and launch app after plist is configured
    home.activation.boring-notch = lib.hm.dag.entryAfter [ "setDarwinPlists" ] ''
      echo "Activating Boring Notch configuration..."
      echo "Configuring Boring Notch settings via plists..." > /tmp/boring-notch-activation.log
      # Remove quarantine attribute from app
      run /usr/bin/xattr -rd com.apple.quarantine /Applications/BoringNotch.app 2>/dev/null || true

      # Add to login items if not already present
      if ! /usr/bin/osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | /usr/bin/grep -q "BoringNotch"; then
        echo "Adding BoringNotch to login items..."
        run /usr/bin/osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/BoringNotch.app", hidden:false}' 2>/dev/null || true
      fi

      # Launch the app if not already running
      if ! /usr/bin/pgrep -x "BoringNotch" > /dev/null 2>&1; then
        echo "Launching BoringNotch..."
        run /usr/bin/open -a "/Applications/BoringNotch.app"
      fi
    '';
  };

}