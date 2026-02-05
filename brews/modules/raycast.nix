{ config, lib, pkgs, user, ... }:

with lib;

let
  cfg = config.brews.raycast;
in
{
  options.brews.raycast = { 
    enable = mkEnableOption "Enable Raycast instead of Spotlight"; 
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "raycast" ];
    };

    system.keyboard.shortcuts = {
      enable = true;
      spotlight.search.enable = false;
    };
  };

  userConfig = mkIf cfg.enable {

    targets.darwin.defaults = {
      "com.raycast.macos" = {
        raycastGlobalHotkey = "Command-49";
      };
    };

    home.activation.configureRaycast = ''
      # Only add to login items if not already present
      if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/Raycast.app"; then
        /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Raycast.app\", hidden:false}"
        /usr/bin/osascript -e 'tell application "Raycast" to launch'
      fi
    '';
  };
}
