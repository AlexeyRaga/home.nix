{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.virtualbox;
in
{
  options.darwin.apps.virtualbox = { enable = mkEnableOption "Enable VirtualBox"; };

  config = mkIf enabled {
    homebrew = {
      taps = [ "homebrew/cask" ];
      casks = [ "virtualbox" "virtualbox-extension-pack" ];
    };
  };
}
