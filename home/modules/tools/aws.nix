{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.aws;

  readCredentials = pkgs.writeShellScript "readCredentials" ''
    cat <&0 | tr -d ' ' | ${pkgs.jo}/bin/jo | ${pkgs.jq}/bin/jq '. | {Version:1, AccessKeyId:.aws_access_key_id, SecretAccessKey:.aws_secret_access_key, SessionToken:.aws_session_token}'
  '';

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
      type = types.attrsOf (types.str);
      default = { };
    };
  };

  config = mkIf cfg.enable
    {
      home.packages = [ pkgs.awscli2 pkgs.ssm-session-manager-plugin ];

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
