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

    home.activation.configureRaycast = 
      let raycastPlist = "${user.home or "~"}/Library/Preferences/com.raycast.macos.plist";
      in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Check if plist file exists, if not initialize it
      if [[ ! -f "${raycastPlist}" ]]; then
        echo "Initializing Raycast preferences plist..."
        /usr/libexec/PlistBuddy \
          -c "Add :raycastGlobalHotkey string" \
          "${raycastPlist}" 2>/dev/null || true
      fi

      /usr/libexec/PlistBuddy \
        -c "Set :raycastGlobalHotkey 'Command-49'" \
        ${raycastPlist}

      /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Raycast.app\", hidden:false}"
      /usr/bin/osascript -e 'tell application "Raycast" to launch'
    '';
  };
}
