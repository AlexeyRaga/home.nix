{ pkgs, config, lib, ... }:

with lib;

{
  tools.aws = {
    sessions = {
      ep = {
        sso_start_url = "https://educationperfect.awsapps.com/start";
        sso_region = "ap-southeast-2";

        profiles = {
          ecr = {
            sso_account_id = "058337015204 ";
            sso_role_name = "readonly";
          };

          test = {
            sso_account_id = "327162508743";
            sso_role_name = "admin";
          };

          dev = {
            sso_account_id = "327162508743";
            sso_role_name = "admin";
          };

          dev-unsafe = {
            sso_account_id = "327162508743";
            sso_role_name = "unsafeterraform";
          };

          staging = {
            sso_account_id = "495236377314";
            sso_role_name = "admin";
          };

          staging-unsafe = {
            sso_account_id = "495236377314";
            sso_role_name = "unsafeterraform";
          };

          live = {
            sso_account_id = "125159634937";
            sso_role_name = "admin";
          };

          live-unsafe = {
            sso_account_id = "125159634937";
            sso_role_name = "unsafeterraform";
          };

          build = {
            sso_account_id = "198994478268";
            sso_role_name = "admin";
          };

          reporting = {
            sso_account_id = "112836601556";
            sso_role_name = "admin";
          };

          canada = {
            sso_account_id = "176806616083";
            sso_role_name = "admin";
            region = "ca-central-1";
          };

          canada-unsafe = {
            sso_account_id = "176806616083";
            sso_role_name = "unsafeterraform";
            region = "ca-central-1";
          };

          live-ca-central-1 = {
            sso_account_id = "176806616083";
            sso_role_name = "admin";
            region = "ca-central-1";
          };
        };
      };
    };
  };
}
