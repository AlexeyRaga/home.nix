{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.raycast;
in
{
  options.darwin.apps.raycast = { enable = mkEnableOption "Enable Raycast instead of Spotlight"; };

  config = mkIf enabled {
    homebrew = {
      casks = [ "raycast" ];
    };

    system.keyboard.shortcuts = {
      enable = true;
      spotlight.search.enable = false;
    };

    targets.darwin.plists = {
      # Disable Spotlight hotkey
      "Library/Preferences/com.raycast.macos.plist" = {
        "raycastGlobalHotkey" = "Command-49";
      };
    };
  };
}
