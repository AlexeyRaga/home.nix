{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.tools.headroom-ai;

in {
  options.tools.headroom-ai = {
    enable = mkEnableOption "Enable headroom-ai";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.rtk
      (pkgs.callPackage ./package.nix { })
    ];

    home.sessionVariables = {
      HEADROOM_OUTPUT_SHAPER = "1";
    };
  };
}
