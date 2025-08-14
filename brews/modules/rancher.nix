{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.rancher;

  # Rancher desktop properties that we care about
  rancherInitConfig = cfg: {
    version = 10;
    application = {
      adminAccess = false;
      pathManagementStrategy = "manual";
      autoStart = cfg.autoStart;
      startInBackground = cfg.startInBackground;
      
      window = {
        quitOnClose = false;
      };

      telemetry = {
        enabled = false;
      };

      extensions = {
        installed = {
          "docker/resource-usage-extension" = "1.0.3";
        };
      };
    };

    containerEngine = {
      name = "moby";
    };

    virtualMachine = {
      memoryInGB = cfg.memoryInGb;
      numberCPUs = cfg.numberCPUs;
      hostResolver =  cfg.hostResolver;
    };

    experimental = {
      virtualMachine = {
        type = cfg.virtualMachine.type;
        useRosetta = cfg.virtualMachine.useRosetta;
        mount = {
          type = cfg.virtualMachine.mountType;
        };
      };
    };

    kubernetes = {
      enabled = cfg.kubernetes.enabled;
      options = {
        traefik = cfg.kubernetes.traefik;
      };
    };
  };

  virtualMachineOptions = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "vz" "qemu" ];
        default = "vz";
        description = "Type of virtual machine to use";
      };
      useRosetta = mkOption {
        type = types.bool;
        default = true;
        description = "Use Rosetta for the virtual machine";
      };

      mountType = mkOption {
        type = types.enum [ "reverse-sshfs" "virtiofs" "9p" ];
        default = "virtiofs";
        description = "Type of mount to use";
      };
    };
  };

  kubernetesOptions = types.submodule {
    options = {
      enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Kubernetes support";
      };
      traefik = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Traefik";
      };
    };
  };
in
{
  options.brews.rancher = { 
    enable = mkEnableOption "Enable Rancher Desktop (replaces Docker Desktop)"; 

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically start Rancher Desktop when the user logs in";
    };

    startInBackground = mkOption {
      type = types.bool;
      default = true;
      description = "Start Rancher Desktop in the background";
    };
    
    memoryInGb = mkOption {
      type = types.int;
      default = 6;
      description = "Amount of memory in Gb to allocate to the virtual machine";
    };

    numberCPUs = mkOption {
      type = types.int;
      default = 2;
      description = "Number of CPUs to allocate to the virtual machine";
    };

    hostResolver = mkOption {
      type = types.bool;
      default = true;
      description = "Enable host resolver for the virtual machine";
    };

    virtualMachine = mkOption {
      type = virtualMachineOptions;
      default = {};
    };

    kubernetes = mkOption {
      type = kubernetesOptions;
      default = {};
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "rancher" ];
    };

    environment.variables = {
      # set it so that tools that expect Docker can find it
      DOCKER_HOST="unix://$HOME/.rd/docker.sock";
    };
  };

  userConfig = mkIf cfg.enable {
    home.sessionVariables = {
      # set it so that tools that expect Docker can find it
      DOCKER_HOST = "unix://$HOME/.rd/docker.sock";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    };

    home.activation.configureRancher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Seed the config file if it doesn't yet exist
      CONFIG_PATH="$HOME/Library/Preferences/rancher-desktop";
      settingsFile="$CONFIG_PATH/settings.json"
      
      mkdir -p $CONFIG_PATH
      if [ ! -e "$settingsFile" ]; then
        # File does not exist, create it
        echo "Rancher Desktop: Writing initial settings.json"
        $DRY_RUN_CMD echo '${builtins.toJSON (rancherInitConfig cfg)}' > "$settingsFile"
      fi
    '';
  };
}
