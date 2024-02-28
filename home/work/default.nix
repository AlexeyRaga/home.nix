{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets;
  epNugetSource = {
    url = "https://nuget.pkg.github.com/EducationPerfect/index.json";
    userName = secrets.github.userName;
    password = secrets.github.token;
  };

  modules = import ../../lib/modules.nix {inherit lib;};
in
{
  imports = [
    ./aws.nix
  ] ++ (modules.importAllModules ./modules);

  home = {
    sessionVariables = {
      EP_NUGET_SOURCE_URL = epNugetSource.url;
      EP_NUGET_SOURCE_USER = epNugetSource.userName;
      EP_NUGET_SOURCE_PASS = epNugetSource.password;
    };
  };

  tools.dotnet = {
    nugetSources = {
      "ep-github" = epNugetSource;
    };
  };

  tools.git = {
    workspaces."src/ep" = {
      user = { email = secrets.github.userEmail; };
      core = { autocrlf = "input"; };
    };
  };

  secureEnv.onePassword = {
    enable = true;
    sessionVariables = {
      FUSIONAUTH_LICENCE = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared DevOps";
        item = "FusionAuth Licences";
        field = "Non-Production";
      };

      EP_NPM_TOKEN = {
        account = "educationperfect.1password.com";
        vault = "Dev - Shared";
        item = "EP_NPM_TOKEN read";
        field = "token";
      };
    };
  };
}
