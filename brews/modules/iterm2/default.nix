{ config, lib, pkgs, user ? {}, ... }:

with lib;

let
  cfg = config.brews.iterm2;
   
  # Create a derivation containing all theme files
  themesPackage = pkgs.runCommand "iterm2-themes" {} ''
    mkdir -p $out
    cp ${./themes}/*.itermcolors $out/
  '';
  
  # Function to get all available themes from the package
  themes = 
    let
      dirContents = builtins.readDir "${themesPackage}";
      themeFiles = lib.filterAttrs (name: type: 
        type == "regular" && lib.hasSuffix ".itermcolors" name
      ) dirContents;
    in
    lib.mapAttrsToList (filename: type: {
      name = lib.removeSuffix ".itermcolors" filename;
      file = "${themesPackage}/${filename}";
    }) themeFiles;

  augmentTheme = themeFile:
    let
      script = pkgs.writeText "augment-iterm2-theme.py" ''
        import plistlib, copy, sys
        with open('${themeFile}', 'rb') as f:
            theme = plistlib.load(f)
        augmented = dict(theme)
        for key in list(theme.keys()):
            if key.endswith('Color'):
                augmented[key + ' (Dark)'] = copy.deepcopy(theme[key])
                augmented[key + ' (Light)'] = copy.deepcopy(theme[key])
        with open(sys.argv[1], 'wb') as f:
            plistlib.dump(augmented, f, fmt=plistlib.FMT_XML)
      '';
    in pkgs.runCommand "augmented-iterm2-theme" {} ''
      ${pkgs.python3.interpreter} ${script} "$out"
    '';

  shell_integration = pkgs.fetchFromGitHub {
    name = "iterm2-shell-integration";
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "4999d188aba9e470fa921367288ab6d5074b5324";
    sha256 = "sha256-HXmZty8emMoUtyuJpLLY+IfHBIJjG9wUJNGv0a3hJBc=";
  };

  utilities = builtins.attrNames (builtins.readDir "${shell_integration}/utilities");
  aliases = lib.concatMapStringsSep ";" (x: "alias ${x}='${shell_integration}/utilities/${x}'") utilities;
in
{
  options.brews.iterm2 = {
    enable = mkEnableOption "Enable iTerm2 - the best terminal for MacOS";

    font = mkOption {
      type = types.str;
      default = "FiraCodeNFM-Reg 12";
    };

    columns = mkOption {
      type = types.ints.positive;
      default = 150;
      description = "Terminal window size (horizontal)";
    };

    rows = mkOption {
      type = types.ints.positive;
      default = 40;
      description = "Terminal window size (vertical)";
    };

    theme = mkOption {
      type = types.nullOr (types.enum (map (theme: theme.name) themes));
      default = null;
      description = "iTerm2 color theme to apply. If null, no theme will be set automatically. Available themes: ${lib.concatStringsSep ", " (map (theme: theme.name) themes)}";
    };

    browserPlugin = mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Install iTerm2 browser plugin to /Applications";
          };
          name = mkOption {
            type = types.str;
            default = "Browser";
            description = "Name of the browser profile";
          };
          shortcut = mkOption {
            type = types.strMatching "^[A-Z0-9]$";
            default = "B";
            description = "Keyboard shortcut for the browser profile";
          };
        };
      };
      default = {};
      description = "Browser plugin configuration";
    };
  };

  systemConfig = mkIf cfg.enable {
      # Install mode: Darwin/homebrew configuration
    homebrew = {
      casks = [ "iterm2" ] ++ optionals cfg.browserPlugin.enable [ "itermbrowserplugin" ];
    };

    # Initialise Shell Integration
    programs.bash.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
      ${aliases}
    '';
    programs.fish.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';
  };

      # Configure mode: Home-manager configuration  
  userConfig = mkIf cfg.enable {
    # Shell integration for home-manager
    programs.bash.initExtra = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
      ${aliases}
    '';
    programs.fish.shellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.initContent = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';

    # Dynamic theme configuration
    home.activation.configureIterm = 
      let 
        itermsPlist = "${user.home or "~"}/Library/Preferences/com.googlecode.iterm2.plist"; 
        
        # Generate commands to install all themes
        themeInstallCommands = lib.concatMapStringsSep "\n" (theme: 
          lib.plists.merge itermsPlist ["Custom Color Presets" theme.name] theme.file
        ) themes;

        # Generate command to apply selected theme if one is specified
        themeApplyCommand =
          let selectedTheme = lib.findFirst (theme: theme.name == cfg.theme) null themes;
          in lib.optionalString (selectedTheme != null)
            (lib.plists.merge itermsPlist ["New Bookmarks" 0] "${augmentTheme selectedTheme.file}");

      in lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        # Check if plist file exists, if not initialize it
        if [[ ! -f "${itermsPlist}" ]]; then
          echo "Initializing iTerm2 preferences plist..."
          /usr/libexec/PlistBuddy \
            -c "Add :'New Bookmarks' array" \
            -c "Add :'New Bookmarks':0 dict" \
            -c "Add :'New Bookmarks':0:'Name' string" \
            -c "Add :'New Bookmarks':0:'Normal Font' string" \
            -c "Add :'New Bookmarks':0:Columns integer" \
            -c "Add :'New Bookmarks':0:Rows integer" \
            -c "Add :'New Bookmarks':0:'Silence Bell' bool" \
            -c "Add :'New Bookmarks':0:'Custom Directory' string" \
            "${itermsPlist}" 2>/dev/null || true
        fi

        /usr/libexec/PlistBuddy \
          -c "Set :'New Bookmarks':0:'Name' 'Default'" \
          -c "Set :'New Bookmarks':0:'Normal Font' '${cfg.font}'" \
          -c "Set :'New Bookmarks':0:'Columns' ${toString cfg.columns}" \
          -c "Set :'New Bookmarks':0:'Rows' ${toString cfg.rows}" \
          -c "Set :'New Bookmarks':0:'Silence Bell' 1" \
          -c "Set :'New Bookmarks':0:'Custom Directory' Recycle" \
          ${itermsPlist}

        # Install all themes
        ${themeInstallCommands}
        
        # Apply selected theme if specified
        ${themeApplyCommand}

        # Configure browser plugin profile if enabled
        ${lib.optionalString cfg.browserPlugin.enable ''
          echo "Configuring iTerm2 browser plugin profile..."
          
          # Search for existing ${cfg.browserPlugin.name} profile
          PROFILE_INDEX=0
          while true; do
            PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print :'New Bookmarks':$PROFILE_INDEX:'Name'" ${itermsPlist} 2>/dev/null) || PROFILE_NAME=""
            if [ -z "$PROFILE_NAME" ]; then
              # No more profiles exist, break and create new one
              break
            elif [ "$PROFILE_NAME" = "${cfg.browserPlugin.name}" ]; then
              # Found existing profile
              break
            fi
            PROFILE_INDEX=$((PROFILE_INDEX + 1))
          done

          # Create new profile if we reached the end without finding one
          if [ -z "$PROFILE_NAME" ] || [ "$PROFILE_NAME" != "${cfg.browserPlugin.name}" ]; then
            echo "Creating new ${cfg.browserPlugin.name} profile at index $PROFILE_INDEX"
            /usr/libexec/PlistBuddy \
              -c "Add :'New Bookmarks':$PROFILE_INDEX dict" \
              -c "Add :'New Bookmarks':$PROFILE_INDEX:'Name' string" \
              -c "Add :'New Bookmarks':$PROFILE_INDEX:'Custom Command' string" \
              -c "Add :'New Bookmarks':$PROFILE_INDEX:'Shortcut' string" \
              ${itermsPlist} 2>/dev/null || true
          fi

          # Set profile properties (whether new or existing)
          /usr/libexec/PlistBuddy \
              -c "Set :'New Bookmarks':$PROFILE_INDEX:'Name' '${cfg.browserPlugin.name}'" \
              -c "Set :'New Bookmarks':$PROFILE_INDEX:'Custom Command' 'Browser'" \
              -c "Set :'New Bookmarks':$PROFILE_INDEX:'Shortcut' '${cfg.browserPlugin.shortcut}'" \
              ${itermsPlist}

          echo "iTerm2 browser plugin profile configured successfully"
        ''}
      '';
  };
}
