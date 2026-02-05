{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.claude;
  
in {
  options.brews.claude = {
    enable = mkEnableOption "Enable Claude - AI assistant for MacOS";
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "claude" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.packages = [ pkgs.claude-code ];
  };
}