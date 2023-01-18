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

  plainCredentialsType = types.submodule {
    options = {
      access_key_id = mkOption { type = types.str; };
      access_secret_key = mkOption { type = types.str; };
    };
  };

  ssoSessionProfileType = types.submodule {
    options = {
      sso_account_id = mkOption { type = types.str; description = "AWS Account ID"; };
      sso_role_name = mkOption { type = types.str; description = "Role name"; };
      region = mkOption { type = types.str; description = "AWS Region to use for this profile"; };
      output = mkOption { type = types.str; default = "json"; };
    };
  };

  ssoSessionType = types.submodule {
    options = {
      sso_startUrl = mkOption { type = types.str; description = "SSO Start URL: https://xxxx.awsapps.com/start"; };
      sso_region = mkOption { type = types.str; description = "AWS Region to use for SSO"; };
      sso_registration_scopes = mkOption { type = types.str; default = "sso:account:access"; };
      profiles = mkOption { type = types.attrsOf ssoSessionProfileType; default = {}; };
    };
  };

  ssoProfileType = types.submodule {
    options = {
      sso_start_url = mkOption { type = types.str; description = "SSO Start URL"; };
      sso_account_id = mkOption { type = types.str; description = "AWS Account ID"; };
      sso_role_name = mkOption { type = types.str; description = "Role name"; };
      sso_region = mkOption { type = types.str; description = "AWS Region to use for SSO"; };
      region = mkOption { type = types.str; description = "AWS Region to use for this profile"; };
      output = mkOption { type = types.str; default = "json"; };
    };
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

      export PLAYWRIGHT_BROWSERS_PATH=0

      ${pkgs.yarn}/bin/yarn --no-default-rc --frozen-lockfile --no-lockfile --non-interactive --no-progress add gsts@${version}

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
      PLAYWRIGHT_BROWSERS_PATH=0 ${gsts}/bin/google-sts \
        --aws-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
        --sp-id "${spid}" \
        --idp-id "${idpid}" \
        --aws-profile "$PROFILE_NAME"
    '';

in
{
  options.tools.aws = {
    enable = mkEnableOption "Enable AWS CLI and profiles";

    credentials = mkOption {
      # type = types.attrsOf (types.oneOf [ plainCredentialsType ssoProfileType] );
      type = types.attrsOf plainCredentialsType;
      # type = types.attrsOf (ssoProfileType);
      default = { };
    };

    sessions = mkOption {
      type = types.attrsOf ssoSessionType;
      default = {};
    };

    ssoProfiles = mkOption {
      type = types.attrsOf ssoProfileType;
      default = {};
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

  config = mkIf cfg.enable
    {
      home.packages =
        let
          accounts = lib.mapAttrsToList (name: value: ''[${name}]="${value.accountId}"'') cfg.googleStsProfile.accounts;
          roles = lib.mapAttrsToList (name: value: ''[${name}]="${toString value.roles}"'') cfg.googleStsProfile.accounts;
          awsSwitchBin = awsSwicth cfg.googleStsProfile.name cfg.googleStsProfile.spId cfg.googleStsProfile.idpId accounts;
          awsSwitchZsh = awsSwitchZshComplete accounts roles;
        in
        [ pkgs.awscli2 pkgs.ssm-session-manager-plugin gsts ] ++ (if (cfg.googleStsProfile.name != { }) then [ awsSwitchBin awsSwitchZsh ] else [ ]);

      home.file.".aws/config".text =
        let
          rmAttr = name: attrs: lib.attrsets.filterAttrs (n: v: n != name) attrs;
          mkProfile = extra: profile:
            lib.mapAttrs' (name: value: { name = "profile ${name}"; value = extra // value; }) profile;

          toCredProcess = file: { credential_process = ''sh -c "cat ${file} | ${readCredentials}"''; };

          credentials = mkProfile {} cfg.credentials;
          ssoProfiles = mkProfile {} cfg.ssoProfiles;

          sessions = lib.concatMapAttrs (name: value:
            let
              header = "sso-session ${name}";
              session = (rmAttr "profiles" value);
              profiles = mkProfile { sso_session = name; } value.profiles;
            in
              { ${header} = session; } // profiles ) cfg.sessions;

          external = lib.mapAttrs' (name: value: { name = "profile ${name}"; value = toCredProcess value; }) cfg.externalCredentials;
        in
          lib.generators.toINI { } (credentials // ssoProfiles // sessions // external);
    };
}
