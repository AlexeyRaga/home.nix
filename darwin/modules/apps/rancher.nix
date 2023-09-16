{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.rancher;
in
{
  options.darwin.apps.rancher = { enable = mkEnableOption "Enable Rancher Desktop (replaces Docker Desktop)"; };

  config = mkIf enabled {
    homebrew = {
      casks = [ "rancher" ];
    };

    environment.variables = {
      # set it so that tools that expect Docker can find it
      DOCKER_HOST="unix://$HOME/.rd/docker.sock";
    };
  };
}
