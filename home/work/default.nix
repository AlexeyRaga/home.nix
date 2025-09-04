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
    pkgs.claude-code
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
      };

      EP_NUGET_SOURCE_USER = {
        account = "educationperfect.1password.com";
        vault = "Employee";
        item = "Github Token";
        field = "username";
      };

      FUSIONAUTH_LICENCE = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared DevOps";
        item = "FusionAuth Licences";
        field = "Non-Production";
      };

      EP_NPM_TOKEN = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared";
        item = "NPM readonly token";
        field = "token";
      };
    };
  };
}
