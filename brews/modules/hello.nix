{ config, lib, pkgs, userConfig ? {}, ... }:

with lib;

let
  cfg = config.brews.hello;
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

  systemConfig = mkIf cfg.enable {
    homebrew = {
      brews = [ "hello" ];
    };
  };

    # Configure mode: Home-manager configuration  
  userConfig = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "hello-custom" ''
        echo "${cfg.greeting}"
        hello
      '')
    ];
  };
}
