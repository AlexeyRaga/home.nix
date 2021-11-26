{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.ep.watchAwsCredentials;
  watchCreds = pkgs.writeShellScript "fswatch-credentials" ''
    ls -al ~/Downloads
    ${pkgs.fswatch}/bin/fswatch -e ".*" -i ".*/credentials$" --event Created --event Updated --event Removed -x $HOME/Downloads -v
    '';

in {
  options.ep.watchAwsCredentials = {
    enable = mkEnableOption "Watch AWS Credentials in Download folder and move them to ~/.aws";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fswatch ];

    launchd.user.agents.aws-credentials-service = {
      serviceConfig = {
        # fswatch -e ".*" -i ".*/test$" --event Created --event Updated --event Removed -x /tmp/1
        ProgramArguments = [
          "${watchCreds}"
          # "${pkgs.fswatch}/bin/fswatch"
          # "-e" ".*"
          # "-i" ".*/credentials$"
          # "--event" "Created"
          # "--event" "Updated"
          # "-x" "/Users/alexey/Public"
          # "-v"
        ];
        WorkingDirectory = "/Users/alexey";
        RunAtLoad = true;
        StandardOutPath = "/tmp/aws-credentials-service.log";
        StandardErrorPath = "/tmp/aws-credentials-service-errors.log";
      };
    };
  };
}
