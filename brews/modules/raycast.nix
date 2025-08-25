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
  };

  userConfig = mkIf cfg.enable {

    home.activation.configureRaycast = 
      let raycastPlist = "~/Library/Preferences/com.raycast.macos.plist";
      in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /usr/libexec/PlistBuddy \
        -c "Set :raycastGlobalHotkey 'Command-49'" \
        ${raycastPlist}
    '';
  };
}
