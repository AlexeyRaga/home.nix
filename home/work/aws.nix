{ pkgs, config, lib, ... }:

with lib;

{
  tools.aws = {
    ssoProfiles = {
      ecr = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "058337015204 ";
        sso_role_name = "readonly";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      test = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "327162508743";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      dev = {
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

      staging-unsafe = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "495236377314";
        sso_role_name = "unsafeterraform";
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

      canada = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_account_id = "176806616083";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ca-central-1";
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
  };
}
