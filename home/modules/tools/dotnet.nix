{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.dotnet;

  dotnet-env = with pkgs; with dotnetCorePackages; combinePackages [
    sdk_6_0
    sdk_7_0
  ];

  buildNugetConfig = nugetSources:
    pkgs.stdenv.mkDerivation {
      name = "nugetConfig";
      phases = [ "installPhase" ];
      buildInputs = with pkgs; [ dotnet-sdk ];
      installPhase =
        let
          toCommand = name: params: ''${dotnet-env}/bin/dotnet nuget add source ${params.url} --name ${name} --username ${params.userName} --password ${params.password} --store-password-in-clear-text'';
          commands = lib.concatStringsSep "\n" (lib.mapAttrsToList toCommand nugetSources);
        in
        ''
          mkdir -p $out
          export HOME=$TMPDIR
          ${commands}
          cp -r $TMPDIR/.nuget $out/
        '';
    };
in
{
  options.tools.dotnet = {
    enable = mkEnableOption "Enable dotnet";

    nugetSources = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          url = mkOption { type = types.str; };
          userName = mkOption { type = types.str; };
          password = mkOption { type = types.str; };
        };
      });
      default = { };
    };
  };

  # 6c64820ffa95db07878b0f4750f4d933d06b52b1

  config = mkIf cfg.enable {
    home.packages = [ dotnet-env ];

    home.sessionVariables = {
      DOTNET_ROOT="${dotnet-env}";
    };

    home.file.".nuget/NuGet/NuGet.Config".source =
      let nugetConfig = buildNugetConfig cfg.nugetSources;
      in "${nugetConfig}/.nuget/NuGet/NuGet.Config";
  };
}
