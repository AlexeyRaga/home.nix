{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.noop;

in
{
  options.services.noop = {
    enable = mkEnableOption "Enable noop service";
  };

  config = mkIf cfg.enable {
    launchd.user.agents.noop-service = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.curl}/bin/curl"
          "google.com"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/noop-service.log";
        StandardErrorPath = "/tmp/noop-service-errors.log";
      };
    };
  };
}
