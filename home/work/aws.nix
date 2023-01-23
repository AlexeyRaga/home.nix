{ pkgs, config, lib, ... }:

with lib;

let
  ### In EP we use Chrome extension for SAML
  ### This extension let us download SAML token as ~/Downloads/credentials
  ### We use this file as per https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
  chromeExtension = pkgs.stdenv.mkDerivation rec {
    pname = "chrome-saml-to-aws";
    version = "56c2dc40a05fee5b7cda80ca72d4165e7669552f";

    src = pkgs.fetchFromGitHub {
      owner = "EducationPerfect";
      repo = "samltoawsstskeys";
      rev = "${version}";
      sha256 = "sha256-4VNHQQQnm1sLdaj7pHtoalW/spt1HPqbwnAJL3QiPDM=";
    };

    buildInputs = with pkgs; [ awscli2 tree ];
    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out/extension
      cp -r * $out/extension
    '';
  };

in
{
  tools.aws = {
    ssoProfiles = {
      test = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "327162508743";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      test-unsafe = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "327162508743";
        sso_role_name = "unsafeterraform";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      staging = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "495236377314";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      live = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "125159634937";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      build = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "198994478268";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      reporting = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "112836601556";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };
    };

    # sessions = {
    #   ep = {
    #     sso_startUrl = "https://educationperfect.aws";
    #     sso_region = "ap-southeast-2";

    #     profiles = {
    #       dev = {
    #         sso_account_id = "327162508743";
    #         sso_role_name = "admin";
    #         region = "ap-southeast-2";
    #       };
    #     };
    #   };
    # };

    googleStsProfile = {
      name = "default";
      spId = "1050940722099";
      idpId = "C02t7lm2d";
      accounts = {
        build = {
          accountId = "198994478268";
          roles = [ "admin" "read-only" ];
        };
        test = {
          accountId = "327162508743";
          roles = [ "admin" "read-only" "unsafe-terraform" ];
        };
        staging = {
          accountId = "495236377314";
          roles = [ "admin" "read-only" "unsafe-terraform" ];
        };
        live = {
          accountId = "125159634937";
          roles = [ "admin" "read-only" "unsafe-terraform" ];
        };
        reporting = {
          accountId = "112836601556";
          roles = [ "admin" "read-only" ];
        };
      };
    };
  };

  home.file.".chrome/saml-to-aws".source = "${chromeExtension}/extension";

  # ssh config for EC2 tools instances
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "test-linux-tools" = {
        user = "ubuntu";
        hostname = "10.0.5.60";
      };
      "staging-linux-tools" = {
        user = "ubuntu";
        hostname = "10.0.2.101";
      };
      "live-linux-tools" = {
        user = "ubuntu";
        hostname = "10.0.3.87";
      };
    };
  };
}
