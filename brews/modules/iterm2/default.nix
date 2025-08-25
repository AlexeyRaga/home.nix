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
  };

  systemConfig = mkIf cfg.enable {
      # Install mode: Darwin/homebrew configuration
    homebrew = {
      casks = [ "iterm2" ];
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
          in lib.optionalString (selectedTheme != null) (
            lib.plists.merge itermsPlist ["New Bookmarks" 0] selectedTheme.file
          );

      in lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        # Install all available themes
        ${themeInstallCommands}

        /usr/libexec/PlistBuddy \
          -c "Set :'New Bookmarks':0:'Normal Font' '${cfg.font}'" \
          -c "Set :'New Bookmarks':0:'Columns' ${toString cfg.columns}" \
          -c "Set :'New Bookmarks':0:'Rows' ${toString cfg.rows}" \
          -c "Set :'New Bookmarks':0:'Silence Bell' 1" \
          -c "Set :'New Bookmarks':0:'Custom Directory' Recycle" \
          ${itermsPlist}

        # Apply selected theme if specified
        ${themeApplyCommand}
      '';
  };
}
