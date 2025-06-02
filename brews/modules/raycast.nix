{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

with lib;

let
  cfg = config.brews.raycast;
  # Import appHelpers if not provided as parameter
  helpers = if appHelpers != null then appHelpers else import ../../lib/app-helpers.nix { inherit lib; };
in
{
  options.brews.raycast = { 
    enable = mkEnableOption "Enable Raycast instead of Spotlight"; 
  };

  config = mkIf cfg.enable (
    helpers.modeSwitchMap appMode {
      # Install mode: Darwin/homebrew configuration
      install = {
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

      # Configure mode: Home-manager configuration  
      configure = {
        # Home-manager doesn't handle system keyboard shortcuts or plists
        # These are system-level configurations that only Darwin can manage
      };
    }
  );
}
