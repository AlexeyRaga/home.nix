{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.aws;

  readCredentials = pkgs.writeShellScript "readCredentials" ''
    cat <&0 | tr -d ' ' | ${pkgs.jo}/bin/jo | ${pkgs.jq}/bin/jq '. | {Version:1, AccessKeyId:.aws_access_key_id, SecretAccessKey:.aws_secret_access_key, SessionToken:.aws_session_token}'
  '';

in
{
  options.tools.aws = {
    enable = mkEnableOption "Enable AWS CLI and profiles";

    profiles = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          accessKeyId = mkOption { type = types.str; };
          accessSecretKey = mkOption { type = types.str; };
        };
      });
      default = {};
    };

    externalCredentials = mkOption {
      type = types.attrsOf(types.string);
      default = {};
    };

    samlProfile = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          credentialsPath = mkOption { type = types.str; };
        };
      });
      default = null;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ pkgs.awscli ];
    }

    (mkIf (cfg.profiles != {}) {
      home.file.".aws/credentials".text =
        let
          toAwsCred = cred: {
            aws_access_key_id = cred.accessKeyId;
            aws_secret_access_key = cred.accessSecretKey;
          };
          mapped = builtins.mapAttrs (name: value: toAwsCred value) cfg.profiles;
        in lib.generators.toINI { } mapped;
    })

    (mkIf (cfg.externalCredentials != {}) {
      home.file.".aws/config".text =
        let
          toCredProcess = file: { credential_process = ''sh -c "cat ${file} | ${readCredentials}"''; };
          mapped = builtins.mapAttrs (name: value: toCredProcess value) cfg.externalCredentials;
        in
          lib.generators.toINI {} mapped;
    })
  ]);
}
