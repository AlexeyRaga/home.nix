{ config, lib, pkgs, ... }:

with lib;
let
  brewBinPrefix = if pkgs.system == "aarch64-darwin" then "/opt/homebrew/bin" else "/usr/local/bin";
  cfg = config.modules.homebrew;
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
in {
  options.modules.homebrew = with types; {
    enable = mkEnableOption "Enable Homebrew";
    taps = mkOption {
      type = listOf str;
      default = [ "homebrew/cask" "homebrew/core" ];
      example = [ "homebrew/cask" ];
      description = "Homebrew formula repositories to tap.";
    };

    brews = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "mas" ];
      description = "Homebrew brews to install.";
    };

    casks = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "hammerspoon" "virtualbox" ];
      description = "Homebrew casks to install.";
    };

    masApps = mkOption {
      type = with types; attrsOf ints.positive;
      default = { };
      example = {
        "1Password" = 1107421413;
        Xcode = 497799835;
      };
      description = ''
        Applications to install from Mac App Store using <command>mas</command>.
        When this option is used, <literal>"mas"</literal> is automatically added to
        <option>homebrew.brews</option>.
        Note that you need to be signed into the Mac App Store for <command>mas</command> to
        successfully install and upgrade applications, and that unfortunately apps removed from this
        option will not be uninstalled automatically even if
        <option>homebrew.cleanup</option> is set to <literal>"uninstall"</literal>
        or <literal>"zap"</literal> (this is currently a limitation of Homebrew Bundle).
        For more information on <command>mas</command> see: https://github.com/mas-cli/mas.
      '';
    };
  };

  config = mkIf enabled {
    home-manager.users."${config.user.name}".home = {
      packages = with pkgs; [ m-cli ];
    };

    homebrew = {
      enable = true;
      brewPrefix = brewBinPrefix;
      autoUpdate = true;
      cleanup = "zap";
      global = {
        brewfile = true;
        noLock = true;
      };

      taps = cfg.taps;
      brews = cfg.brews;
      casks = cfg.casks;
      masApps = cfg.masApps;
    };
  };
}
