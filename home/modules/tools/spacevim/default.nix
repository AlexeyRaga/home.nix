{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.tools.spacevim;
  spacevim = pkgs.spacevim.override {spacevim_config = import ./init.config;};
in
{

  options.tools.spacevim = {
    enable = mkEnableOption "Enable SpaceVim";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      spacevim
    ];

    programs.neovim = {
      enable = true;
      vimAlias = true;
      withPython3 = true;
    };

    home.sessionVariables = {
      EDITOR = "${pkgs.spacevim}/bin/spacevim";
    };
  };
}
