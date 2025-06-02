{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

with lib;

let
  cfg = config.brews.hello;
  # Import appHelpers if not provided as parameter
  helpers = if appHelpers != null then appHelpers else import ../lib/app-helpers.nix { inherit lib; };
in
{
  options.brews.hello = {
    enable = mkEnableOption "Enable Hello app with custom greeting";

    greeting = mkOption {
      type = types.str;
      default = "Hello, World!";
      description = "Custom greeting message";
    };
  };

  config = mkIf cfg.enable (helpers.modeSwitchMap appMode {
    # Install mode: Darwin/homebrew configuration
    install = {
      homebrew = {
        brews = [ "hello" ];
      };
    };

    # Configure mode: Home-manager configuration  
    configure = {
      home.packages = [
        (pkgs.writeShellScriptBin "hello-custom" ''
          echo "${cfg.greeting}"
          hello
        '')
      ];
    };
  });
}
