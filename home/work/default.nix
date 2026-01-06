{ config, lib, pkgs, userConfig, ... }:

let

  modules = import ../../lib/modules.nix {inherit lib;};
in
{
  imports = [
    ./aws.nix
  ] ++ (modules.importAllModules ./modules);

  home = {
    sessionVariables = {
    };
  };

  home.packages = [
    pkgs.github-copilot-cli
  ];

  tools.dotnet = {
    nugetSources = {
      "ep-github" = {
        url = "https://nuget.pkg.github.com/EducationPerfect/index.json";
        userName = "%EP_NUGET_SOURCE_USER%";
        password = "%EP_NUGET_SOURCE_PASS%";
      };
    };
  };

  secureEnv.onePassword = {
    enable = true;
    sessionVariables = {
      EP_NUGET_SOURCE_PASS = {
        account = "educationperfect.1password.com";
        vault = "Employee";
        item = "Github Token";
        field = "password";
        required = true; # Critical for work development
      };

      EP_NUGET_SOURCE_USER = {
        account = "educationperfect.1password.com";
        vault = "Employee";
        item = "Github Token";
        field = "username";
        required = true; # Critical for work development
      };

      FUSIONAUTH_LICENCE = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared DevOps";
        item = "FusionAuth Licences";
        field = "Non-Production";
        required = false; # Optional for local dev
      };

      EP_NPM_TOKEN = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared";
        item = "NPM readonly token";
        field = "token";
        required = true; # Needed for package installation
      };
    };
  };
}
