{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.aws;

  readCredentials = pkgs.writeShellScript "readCredentials" ''
    cat <&0 | tr -d ' ' | ${pkgs.jo}/bin/jo | ${pkgs.jq}/bin/jq '. | {Version:1, AccessKeyId:.aws_access_key_id, SecretAccessKey:.aws_secret_access_key, SessionToken:.aws_session_token}'
  '';

  writeScriptDir = path: text:
    pkgs.writeTextFile {
      inherit text;
      executable = true;
      name = builtins.baseNameOf path;
      destination = "/${path}";
    };

  gsts = pkgs.stdenv.mkDerivation rec {
    pname = "gsts";
    version = "4.0.1";

    phases = [ "configurePhase" "installPhase" ];
    buildInputs = with pkgs; [ nodejs yarn makeWrapper ];


    installPhase = ''
      TMP=`mktemp -d`
      cd $TMP

      HOME=$TMP

      yarn --no-default-rc --frozen-lockfile --no-lockfile --non-interactive --no-progress add gsts@${version}

      mkdir -p $out/bin
      cp -r * $out/

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/google-sts --add-flags $out/node_modules/gsts/index.js
    '';
  };


  awsSwitchZshComplete = accounts: roles:
    writeScriptDir "/share/zsh/site-functions/_aws-switch" ''
      #compdef aws-switch

      typeset -A opt_args

      _aws-switch() {
        local state

        declare -A AWS_ACCOUNTS
        AWS_ACCOUNTS=(${toString accounts})

        declare -A ROLE_NAMES
        ROLE_NAMES=(${toString roles})

        _arguments \
          '1: :->account_name'\
          '2: :->role_name' \
        && ret=0

        case $state in
          (account_name) compadd "$@" -k AWS_ACCOUNTS;;
          (role_name) compadd "$@" ''${=ROLE_NAMES[$words[2]]}
            # (*) compadd "$@" prod staging dev
        esac
      }

      _aws-switch "$@"
    '';

  awsSwicth = name: spid: idpid: accounts:
    pkgs.writeShellScriptBin "aws-switch" ''
      set -e
      declare -A AWS_ACCOUNTS
      AWS_ACCOUNTS=(${toString accounts})

      ACCOUNT_NAME=$1
      ACCOUNT_ID=''${AWS_ACCOUNTS[$ACCOUNT_NAME]}
      ROLE_NAME=''${2:-admin}

      PROFILE_NAME="''${3:-${name}}"

      echo "Switching profile '$PROFILE_NAME' to account $ACCOUNT_NAME ($ACCOUNT_ID) with role '$ROLE_NAME'"
      ${gsts}/bin/google-sts \
        --aws-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
        --sp-id "${spid}" \
        --idp-id "${idpid}" \
        --aws-profile "$PROFILE_NAME"
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
      default = { };
    };

    externalCredentials = mkOption {
      type = types.attrsOf (types.string);
      default = { };
    };

    googleStsProfile = mkOption {
      type = types.submodule {
        options = {
          name = mkOption { type = types.str; description = "Name of the AWS profile"; };
          spId = mkOption { type = types.str; description = "Google Service Provider ID (SP ID)"; };
          idpId = mkOption { type = types.str; description = "Google Identity Provider ID (IDP ID)"; };
          accounts = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  accountId = mkOption { type = types.str; description = "AWS account ID (123456789012)"; };
                  roles = mkOption { type = types.listOf (types.str); description = "AWS roles (admin, readonly, etc)"; };
                };
              });
          };
        };
      };
      default = { };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages =
        let
          accounts = lib.mapAttrsToList (name: value: ''[${name}]="${value.accountId}"'') cfg.googleStsProfile.accounts;
          roles = lib.mapAttrsToList (name: value: ''[${name}]="${toString value.roles}"'') cfg.googleStsProfile.accounts;
          awsSwitchBin = awsSwicth cfg.googleStsProfile.name cfg.googleStsProfile.spId cfg.googleStsProfile.idpId accounts;
          awsSwitchZsh = awsSwitchZshComplete accounts roles;
        in
        [ pkgs.awscli gsts ] ++ (if (cfg.googleStsProfile.name != { }) then [ awsSwitchBin awsSwitchZsh ] else [ ]);
    }

    (mkIf (cfg.externalCredentials != { }) {
      home.file.".aws/config".text =
        let
          toCredProcess = file: { credential_process = ''sh -c "cat ${file} | ${readCredentials}"''; };
          toAwsCred = cred: { aws_access_key_id = cred.accessKeyId; aws_secret_access_key = cred.accessSecretKey; };

          credentials = lib.mapAttrs' (name: value: { name = "profile ${name}"; value = toAwsCred value; }) cfg.profiles;
          external = lib.mapAttrs' (name: value: { name = "profile ${name}"; value = toCredProcess value; }) cfg.externalCredentials;
        in
        lib.generators.toINI { } (credentials // external);
    })
  ]);
}
