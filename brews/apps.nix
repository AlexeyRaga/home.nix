# Default app configurations
# This file defines which apps are enabled and their global settings.
# All .nix files in this directory are automatically imported by both 
# Darwin and home-manager configurations via importAppModules.
{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

{
  # Enable greeter app with shared configuration
  brews.greeter = {
    enable = true;
    greeting = "Hello from GREETER!";
  };

  brews.hello = {
    enable = true;
    greeting = "Hello from HELLO!";
  };

  # Add other shared app configurations here as needed
  # brews.someOtherApp = {
  #   enable = true;
  #   someOption = "value";
  # };
}
