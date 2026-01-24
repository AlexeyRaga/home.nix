{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.meetingbar;
in 
{
  options.brews.meetingbar = {
    enable = mkEnableOption "Enable MeetingBar - calendar and meeting menu bar app for MacOS";

    fullscreenNotification = mkOption {
      type = lib.types.int;
      default = 1;
      description = "Fullscreen notification setting.";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "meetingbar" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.activation.configureMeetingBar = ''
      # Only add to login items if not already present
      if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/MeetingBar.app"; then
        $DRY_RUN_CMD /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/MeetingBar.app\", hidden:false}"
        $DRY_RUN_CMD /usr/bin/osascript -e 'tell application "MeetingBar" to launch'
      fi

      $DRY_RUN_CMD /usr/bin/defaults write leits.MeetingBar fullscreenNotification -int ${toString cfg.fullscreenNotification}
    '';
  };
}
