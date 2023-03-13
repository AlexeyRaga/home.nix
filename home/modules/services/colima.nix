{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.colima;
  requiredPackages = with pkgs; [ colima docker ];

  colimaWatcher = cfg:
    let
      colimaBin = "${pkgs.colima}/bin/colima";
      extraDns = lib.concatMapStringsSep " " (x: "--dns='${x}'") cfg.config.network.dns;
      extraDnsHosts = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--dns-host='${k}=${v}'") cfg.config.network.dnsHosts);
    in
      pkgs.writeShellScript "colima-watcher" ''
        function cleanup {
          echo "stopping Colima"
          ${colimaBin} stop --force
        }

        trap cleanup EXIT

        ${colimaBin} start \
        --activate=${boolToString cfg.config.autoActivate} \
        --cpu=${toString cfg.config.cpu} \
        --memory=${toString cfg.config.memory} \
        --network-address=${boolToString cfg.config.network.address} \
        ${extraDns} \
        ${extraDnsHosts} \
        --ssh-agent=${boolToString cfg.config.forwardAgent} \
        --ssh-config=${boolToString cfg.config.sshConfig} \
        --verbose

        set -e
        while true; do
          ${colimaBin} status > /dev/null 2>&1
          sleep 5
        done
      '';

  networkOpts = types.submodule {
    options = {
      address = mkOption {
        type = types.bool;
        default = false;
        description = "Assign reachable IP address to the virtual machine";
      };

      dns = mkOption {
        type = types.listOf (types.strMatching "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+");
        default = [];
        description = "Custom DNS resolvers for the virtual machine";
      };

      dnsHosts = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "DNS hostnames to resolve to custom targets using the internal resolver";
      };
    };
  };

  colimaOpts = types.submodule {
    options = {

      cpu = mkOption {
        type = types.ints.positive;
        default = 2;
        description = "Number of CPUs to be allocated to the virtual machine";
      };

      memory = mkOption {
        type = types.ints.positive;
        default = 2;
        description = "Size of the disk in GiB to be allocated to the virtual machine";
      };

      autoActivate = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-activate on the Host for client access";
      };

      network = mkOption {
        type = networkOpts;
        default = {};
        description = "Network configurations for the virtual machine";
      };

      forwardAgent = mkOption {
        type = types.bool;
        default = false;
        description = "Forward the host's SSH agent to the virtual machine.";
      };

      docker = mkOption {
        type = types.nullOr types.attrs;
        default = null;
        description = "Docker daemon configuration that maps directly to daemon.json (https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file)";
      };

      sshConfig = mkOption {
        type = types.bool;
        default = true;
        description = "Modify ~/.ssh/config automatically to include a SSH config for the virtual machine";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the virtual machine";
      };

    };
  };
in
{
  options.services.colima = {
    enable = mkEnableOption "Enable Colima";

    config = mkOption {
      type = colimaOpts;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    home.packages = requiredPackages;

    launchd.agents = {
      colima = {
        enable = true;

        config = {
          KeepAlive = true;
          RunAtLoad = true;
          WorkingDirectory = (builtins.getEnv "HOME");
          ProgramArguments = [
            "${colimaWatcher cfg}"
          ];
          EnvironmentVariables = {
            PATH =
              (lib.makeBinPath requiredPackages)
              + ":/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
            ;
          };
        };
      };
    };
  };
}
