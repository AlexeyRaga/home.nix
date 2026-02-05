{ config, lib, pkgs, user, ... }:

with lib;

let
  cfg = config.spotlight;
in
{
  options.spotlight = {
    excludePaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "/nix" "${user.home}/src" ];
      description = ''
        List of paths to exclude from Spotlight indexing.
        These paths will be added to the Spotlight Privacy exclusion list.
      '';
    };
  };

  config = mkIf (cfg.excludePaths != []) {
    system.activationScripts.postActivation.text = ''
      echo "Configuring Spotlight exclusions..."
      
      PLIST="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
      
      if [ -f "$PLIST" ]; then
        # Ensure Exclusions array exists
        /usr/libexec/PlistBuddy -c "Print :Exclusions" "$PLIST" &>/dev/null || \
          /usr/libexec/PlistBuddy -c "Add :Exclusions array" "$PLIST"
        
        # Add each exclusion path
        ${concatMapStringsSep "\n" (path: ''
          /usr/libexec/PlistBuddy -c "Add :Exclusions: string ${path}" "$PLIST" 2>/dev/null || true
        '') cfg.excludePaths}
        
        echo "Spotlight exclusions configured: ${toString cfg.excludePaths}"
        echo "Restarting metadata server..."
        
        # Restart metadata service to pick up changes
        /bin/launchctl stop com.apple.metadata.mds 2>/dev/null || true
        /bin/sleep 2
        /bin/launchctl start com.apple.metadata.mds 2>/dev/null || true
        
        # echo "Done. Verify with: sudo /usr/libexec/PlistBuddy -c 'Print :Exclusions' $PLIST"
      else
        echo "WARNING: $PLIST not found. Add at least one exclusion via GUI first."
      fi
    '';
  };
}