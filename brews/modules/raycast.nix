{ config, lib, pkgs, ... }:

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

    targets.darwin.plists = {
      # Disable Spotlight hotkey
      "Library/Preferences/com.raycast.macos.plist" = {
        "raycastGlobalHotkey" = "Command-49";
      };
    };
  };

  userConfig = mkIf cfg.enable {
    # Home-manager doesn't handle system keyboard shortcuts or plists
    # These are system-level configurations that only Darwin can manage
  };
}
