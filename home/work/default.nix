let
  secrets = import ./secrets;
  epNugetSource = {
    url = "https://nuget.pkg.github.com/EducationPerfect/index.json";
    userName = secrets.github.userName;
    password = secrets.github.token;
  };

in
{
  imports = [
    ./aws.nix
  ];

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
      core = { autocrlf = true; };
    };
  };
}
