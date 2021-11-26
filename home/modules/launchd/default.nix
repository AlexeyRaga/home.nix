{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launchd;
  homeCfg = config.home;

  wrapSystemdSocketActivation = c:
    if c.systemdSocketActivation then
      recursiveUpdate c {
        serviceConfig.Program = "${pkgs.launchd_shim}/bin/launchd_shim";
        serviceConfig.ProgramArguments = [ "${pkgs.launchd_shim}/bin/launchd_shim" ] ++ (
          if c.serviceConfig.ProgramArguments == null then
            [ c.serviceConfig.Program ]
          else
            c.serviceConfig.ProgramArguments);
        serviceConfig.EnvironmentVariables.LISTEN_FDNAMES = concatStringsSep ":" (mapAttrsToList (name: value: name) c.serviceConfig.Sockets);
      }
    else c;

  buildLaunchAgent = c:
    (wrapSystemdSocketActivation c).serviceConfig;

  buildLaunchAgentFile = name: value: {
    name = "/Library/LaunchAgents/${value.serviceConfig.Label}.plist";
    value.text = generators.toPlist {} (buildLaunchAgent value);
  };

  launchdConfig = import ./launchd.nix;

  serviceOptions =
    { config, name, ... }:

    {
      options = {
        systemdSocketActivation = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Set LISTEN_FDS, LISTEN_FDNAMES and LISTEN_PID to be compatible with systemd socket activation.
          '';
        };

        serviceConfig = mkOption {
          type = types.submodule launchdConfig;
          example = {
            Program = "/run/current-system/sw/bin/nix-daemon";
            KeepAlive = true;
          };
          default = {};
          description = ''
            Each attribute in this set specifies an option for a key in the plist.
            <link xlink:href="https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html"/>
          '';
        };
      };

      config = {
        serviceConfig.Label = mkDefault "${cfg.labelPrefix}.${name}";
        serviceConfig.EnvironmentVariables.NIX_SSL_CERT_FILE = mkDefault "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
    };
in

{
  options = {
    launchd.labelPrefix = mkOption {
      type = types.str;
      default = "org.nixos";
      description = ''
        The default prefix of the service label. Individual services can
        override this by setting the Label attribute.
      '';
    };

    launchd.user.agents = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = ''
        Definition of per-user launchd agents.

        When a user logs in, a per-user launchd is started.
        It does the following:
        1. It loads the parameters for each launch-on-demand user agent from the property list files found in /System/Library/LaunchAgents, /Library/LaunchAgents, and the user’s individual Library/LaunchAgents directory.
        2. It registers the sockets and file descriptors requested by those user agents.
        3. It launches any user agents that requested to be running all the time.
        4. As requests for a particular service arrive, it launches the corresponding user agent and passes the request to it.
        5. When the user logs out, it sends a SIGTERM signal to all of the user agents that it started.
      '';
    };
  };

  config =
  {
    home.file = mapAttrs' buildLaunchAgentFile cfg.user.agents;
    home.activation.reloadLaunchd = hm.dag.entryAfter ["linkGeneration"] ''
      sh ${./launchd-activate.sh} "''${oldGenPath=}" "$newGenPath"
    '';
  };
}
