{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

with lib;

let
  cfg = config.brews.greeter;
  # Import appHelpers if not provided as parameter
  helpers = if appHelpers != null then appHelpers else import ../lib/app-helpers.nix { inherit lib; };
in
{
  options.brews.greeter = {
    enable = mkEnableOption "Enable Hello app with custom greeting";

    greeting = mkOption {
      type = types.str;
      default = "Hello, World!";
      description = "Custom greeting message";
    };

    # Internal option for homebrew configuration
    homebrew = mkOption {
      type = types.attrs;
      default = {};
      internal = true;
      description = "Homebrew configuration for this app";
    };
  };

  config = mkIf cfg.enable (
    helpers.modeSwitchMap appMode {
      # Install mode: Darwin/homebrew configuration
      install = {
        brews.greeter.homebrew = {
          brews = [ "hello" ];
        };
      };

      # Configure mode: Home-manager configuration  
      configure = {
        home.file."iamhere.txt".text = "I am here!";
        home.packages = [
          (pkgs.writeShellScriptBin "greeter-custom" ''
            echo "${cfg.greeting}"
            hello
          '')
        ];
      };
    }
  );
}
