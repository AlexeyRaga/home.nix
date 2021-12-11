{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.dotnet;

  buildNugetConfig = nugetSources:
    pkgs.stdenv.mkDerivation {
      name = "nugetConfig";
      phases = [ "installPhase" ];
      buildInputs = with pkgs; [ dotnet-sdk jq tree ];
      installPhase =
        let
          toLine = line: ''dotnet nuget add source ${line.url} --name ${line.name} --username ${line.userName} --password ${line.password} --store-password-in-clear-text'';
          commands = lib.concatMapStringsSep "\n" toLine cfg.nugetSources;
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
      type = types.listOf (types.submodule {
        options = {
          url = mkOption { type = types.str; };
          name = mkOption { type = types.str; };
          userName = mkOption { type = types.str; };
          password = mkOption { type = types.str; };
        };
      });
      default = [ ];
    };
  };

  # 6c64820ffa95db07878b0f4750f4d933d06b52b1

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dotnet-sdk
    ];

    home.file.".nuget/NuGet/NuGet.Config".source =
      let nugetConfig = buildNugetConfig cfg.nugetSources;
      in "${nugetConfig}/.nuget/NuGet/NuGet.Config";
  };
}
