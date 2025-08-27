{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.vscode;

  codeBin = ''/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'';
  settingsFile = "$HOME/Library/Application Support/Code/User/settings.json";

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
  options.brews.vscode = {
    enable = mkEnableOption "Enable VSCode";

    extensions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of required extensions";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "visual-studio-code" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.activation.configureVSCode = lib.hm.dag.entryAfter [ "writeBoundary" ] 
      (let currentBundleContent = builtins.concatStringsSep "\n" (lib.lists.unique (lib.lists.sort (a: b: a < b) cfg.extensions));
      in ''
        # Ensure VSCode directories exist for the user
        mkdir -p "$HOME/Library/Application Support/Code/User"
        mkdir -p "$HOME/.vscode/extensions"

        if [ ! -e "${settingsFile}" ]; then
          echo "VSCode: Writing default settings.json"
          $DRY_RUN_CMD echo '${builtins.replaceStrings ["'"] ["'\"'"] (builtins.toJSON defaultSettings)}' > "${settingsFile}"
        fi

        bundle_file="$HOME/.vscode/extensions/extensions.nix.bundle"

        # Get extension lists (these are newline-separated strings, not arrays)
        installed_exts=$(${codeBin} --list-extensions | tr '[:upper:]' '[:lower:]')
        wanted_exts=$(echo "${currentBundleContent}" | tr '[:upper:]' '[:lower:]')
        
        if [ -f "$bundle_file" ]; then
          bundled_exts=$(cat "$bundle_file" | tr '[:upper:]' '[:lower:]')
        else
          bundled_exts=""
        fi

        # Find extensions to install (in wanted but not installed)
        mapfile -t to_install < <(comm -23 <(echo "$wanted_exts" | sort -u) <(echo "$installed_exts" | sort -u))

        # Find extensions to remove (in bundled AND installed but NOT wanted)
        if [ -n "$bundled_exts" ]; then
          # Step 1: Find extensions in bundled but not in wanted
          bundled_not_wanted=$(comm -23 <(echo "$bundled_exts" | sort -u) <(echo "$wanted_exts" | sort -u))
          # Step 2: Find which of those are also installed
          mapfile -t to_remove < <(comm -12 <(echo "$installed_exts" | sort -u) <(echo "$bundled_not_wanted" | sort -u))
        else
          to_remove=()
        fi

        if [ ''${#to_install[@]} -gt 0 ]; then
          install_args=()
          for ext in "''${to_install[@]}"; do
            install_args+=(--install-extension "$ext")
          done
          $DRY_RUN_CMD ${codeBin} "''${install_args[@]}"
        fi

        if [ ''${#to_remove[@]} -gt 0 ]; then
          remove_args=()
          for ext in "''${to_remove[@]}"; do
            remove_args+=(--uninstall-extension "$ext")
          done
          $DRY_RUN_CMD ${codeBin} "''${remove_args[@]}"
        fi

        echo "${currentBundleContent}" > "$bundle_file"
      '');
  };
}