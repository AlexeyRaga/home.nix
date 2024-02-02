{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.rancher;

  # where the Rancher Desktop config is going to be initialised
  rancherConfigPath = "${config.user.home}/Library/Preferences/rancher-desktop";

  # Rancher desktop properties that we care about
  rancherInitConfig = {
    version = 10;
    application = {
      adminAccess = false;
      pathManagementStrategy = "manual";
      autoStart = true;
      startInBackground = true;
      
      window = {
        quitOnClose = false;
      };

      telemetry = {
        enabled = false;
      };

      extensions = {
        installed = {
          "julianb90/tachometer" = "0.0.3";
        };
      };
    };

    containerEngine = {
      name = "moby";
    };

    virtualMachine = {
      memoryInGB = 6;
      numberCPUs = 2;
      hostResolver =  true;
    };

    experimental = {
      virtualMachine = {
        type = "vz";
        useRosetta = true;
      };
    };

    kubernetes = {
      enabled = false;
      options = {
        traefik = false;
      };
    };
  };

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

    # Seed the config file if it doesn't yet exist
    system.activationScripts.postUserActivation.text = ''
      $DRY_RUN_CMD mkdir -p ${rancherConfigPath}
      settingsFile="${rancherConfigPath}/settings.json"
      if [ ! -e "$settingsFile" ]; then
        # File does not exist, create it
        $DRY_RUN_CMD echo '${builtins.toJSON rancherInitConfig}' > "$settingsFile"
      fi
    '';
  };
}
