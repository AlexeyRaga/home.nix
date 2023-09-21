{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.tools.skim;
in
{

  options.tools.skim = {
    enable = mkEnableOption "Enable Skim";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.ripgrep ];

    programs.skim = {
      enable = true;

      changeDirWidgetOptions = [
        "--preview 'tree -C {} | head -200'"
      ];
    };

    programs.zsh.shellAliases = {
      skbat = "sk --ansi -c '${pkgs.ripgrep}/bin/rg --files' --preview='bat {} --color=always'";
    };

  };
}
