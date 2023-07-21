{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.vscode;

  codeBin = ''/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'';

in
{
  options.darwin.apps.vscode = {
    enable = mkEnableOption "Enable VSCode";

    extensions =  mkOption {
       type = types.listOf types.str;
       default = [];
       description = "List of required extensions";
    };
  };

  config = mkIf enabled {
    # Install VSCode from Homebrew
    homebrew = {
      casks = [ "visual-studio-code" ];
    };

    system.activationScripts.postUserActivation.text =
      let currentBundleContent = builtins.concatStringsSep "\n" (lib.lists.unique (lib.lists.sort (a: b: a < b) cfg.extensions));
      in ''
      normalColor="$(tput sgr0)"
      noteColor="$(tput bold)$(tput setaf 6)"

      bundle_file="$HOME/.vscode/extensions/extensions.nix.bundle"

      # Sort the arrays and remove duplicates
      installed_exts=$(${codeBin} --list-extensions | sort -u)
      wanted_exts="${currentBundleContent}"

      [ -f "$bundle_file" ] && bundled_exts=$(cat $bundle_file | sort -u) || bundled_exts=""

      to_install=( $(comm -23 <(echo "$wanted_exts") <(echo "$installed_exts")) )

      # Find elements that are in both stored_exts and installed_exts but not in wanted_exts
      to_remove=($(comm -23 <(echo "$bundled_exts") <(echo "$wanted_exts") | comm -12 <(echo "$installed_exts") -))

      echo "''${noteColor}Setting VSCode extensions''${normalColor}"

      if [ ''${#to_install[@]} -gt 0 ]; then
        $DRY_RUN_CMD ${codeBin} ''${to_install[*]/#/--install-extension }
      fi

      if [ ''${#to_remove[@]} -gt 0 ]; then
        $DRY_RUN_CMD ${codeBin} ''${to_remove[*]/#/--uninstall-extension }
      fi

      echo "${currentBundleContent}" > $bundle_file
    '';
  };
}
