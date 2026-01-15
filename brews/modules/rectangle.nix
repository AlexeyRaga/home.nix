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
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "rectangle" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.activation.configureRaycast = ''
      # Only add to login items if not already present
      if ! /usr/bin/osascript -e "tell application \"System Events\" to get the path of every login item" | grep -q "/Applications/Rectangle.app"; then
        /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Rectangle.app\", hidden:false}"
        /usr/bin/osascript -e 'tell application "Rectangle" to launch'
      fi
    '';
  };
}