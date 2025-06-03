{ config, lib, pkgs, userConfig ? {}, ... }:

with lib;

let
  cfg = config.brews.greeter;
in
{
  options.brews.greeter = {
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

  userConfig = mkIf cfg.enable {
    home.file."iamhere.txt".text = "I am here!";
    home.packages = [
      (pkgs.writeShellScriptBin "greeter-custom" ''
        echo "${cfg.greeting}"
        hello
      '')
    ];
  };
}
