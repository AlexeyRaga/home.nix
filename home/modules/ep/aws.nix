{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.aws;

  readCredentials = pkgs.writeShellScriptBin "awsReadSamlCredentials" ''
    cat <&0 | tr -d ' ' | jo | jq '. | {Version:1, AccessKeyId:.aws_access_key_id, SecretAccessKey:.aws_secret_access_key, SessionToken:.aws_session_token}'
  '';
  chromeExtension = pkgs.stdenv.mkDerivation rec {
    pname = "chrome-saml-to-aws";
    version = "56c2dc40a05fee5b7cda80ca72d4165e7669552f";

    src = pkgs.fetchFromGitHub {
      owner = "EducationPerfect";
      repo = "samltoawsstskeys";
      rev = "${version}";
      sha256 = "sha256-4VNHQQQnm1sLdaj7pHtoalW/spt1HPqbwnAJL3QiPDM=";
    };

    buildInputs = with pkgs; [ awscli tree ];
    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

in
{
  options.tools.aws = {
    enable = mkEnableOption "Enable AWS CLI and profiles";
    profiles = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          accessKeyId = mkOption { type = types.str; };
          accessSecretKey = mkOption { type = types.str; };
        };
      });
      default = [ ];
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

    (mkIf (cfg.profiles != [ ]) {
      home.file.".aws/credentials".text =
        let toAwsCred = cred: {
          "${cred.name}" = {
            aws_access_key_id = cred.accessKeyId;
            aws_secret_access_key = cred.accessSecretKey;
          };
        };
        in concatMapStringsSep "\n" (x: lib.generators.toINI { } (toAwsCred x)) cfg.profiles;
    })

    (mkIf (cfg.samlProfile != null) {
      home.packages = [
        pkgs.jo
        pkgs.jq
        readCredentials
        chromeExtension
      ];

      home.file.".chrome/saml-to-aws".source = "${chromeExtension}";

      home.file.".aws/config".text = ''
        [${cfg.samlProfile.name}]
        credential_process = sh -c "cat ~/Downloads/credentials | awsReadSamlCredentials"
      '';
    })

  ]);
}
