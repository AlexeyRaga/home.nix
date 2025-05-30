{ config, lib, pkgs, ... }:

# Comparable to jq / yq, but supports JSON, YAML, TOML, XML and CSV with zero runtime dependencies.

with lib;

let
  cfg = config.tools.dasel;

in {

  options.tools.dasel = {
    enable = mkEnableOption "Enable Dasel";

    enableBashIntegration = mkEnableOption "dasel's bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "dasel's zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "dasel's fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.dasel ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source ${pkgs.dasel}/share/bash-completion/completions/dasel.bash
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      source ${pkgs.dasel}/share/zsh/site-functions/_dasel
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${pkgs.dasel}/share/fish/vendor_completions.d/dasel.fish
    '';
  };
}
