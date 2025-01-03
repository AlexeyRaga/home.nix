{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.vscode;

  codeBin = ''/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'';
  settingsFile = ''${config.user.home}/Library/Application Support/Code/User/settings.json'';

  defaultSettings = {
    workbench.colorTheme = "Default Dark Modern";
    workbench.iconTheme = "vscode-icons";
    git.autofetch = true;
    editor.fontFamily = "'FiraCode Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
    editor.fontLigatures = true;
    editor.fontSize = 12;
  };

in 
{
  options.darwin.apps.vscode = {
    enable = mkEnableOption "Enable VSCode";

    extensions = mkOption {
      type = types.listOf types.str;
      default = [ ];
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

        if [ ! -e "${settingsFile}" ]; then
          echo "''${noteColor}VSCode: Writing default settings.json''${normalColor}"
          $DRY_RUN_CMD echo '${builtins.replaceStrings ["'"] ["'\"'"] (builtins.toJSON defaultSettings)}' > "${settingsFile}"
        fi

        bundle_file="$HOME/.vscode/extensions/extensions.nix.bundle"

        # Sort the arrays and remove duplicates
        installed_exts=$(${codeBin} --list-extensions | sort -u)
        wanted_exts="${currentBundleContent}"

        [ -f "$bundle_file" ] && bundled_exts=$(sort -u "$bundle_file") || bundled_exts=""

        mapfile -t to_install < <(comm -23 <(echo "$wanted_exts") <(echo "$installed_exts"))

        # Find elements that are in both stored_exts and installed_exts but not in wanted_exts
        mapfile -t to_remove < <(comm -23 <(echo "$bundled_exts") <(echo "$wanted_exts") | comm -12 <(echo "$installed_exts") -)

        echo "''${noteColor}VSCode: Setting extensions''${normalColor}"

        if [ ''${#to_install[@]} -gt 0 ]; then
          $DRY_RUN_CMD ${codeBin} "''${to_install[*]/#/--install-extension }"
        fi

        if [ ''${#to_remove[@]} -gt 0 ]; then
          $DRY_RUN_CMD ${codeBin} "''${to_remove[*]/#/--uninstall-extension }"
        fi

        echo "${currentBundleContent}" > "$bundle_file"
      '';
  };
}
