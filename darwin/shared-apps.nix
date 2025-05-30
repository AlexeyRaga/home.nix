{ config, lib, pkgs, userConfig, ... }:

with lib;

let
  cfg = config.brews;
  
  # Helper function to collect homebrew configs from all enabled apps
  collectHomebrewConfigs = appConfigs:
    let
      enabledApps = filterAttrs (name: app: app.enable or false) appConfigs;
      homebrewConfigs = mapAttrsToList (name: app: app.homebrew or {}) enabledApps;
    in
    foldl recursiveUpdate {} homebrewConfigs;

in
{
  config = {
    # Dynamically collect homebrew configurations from all enabled shared apps
    homebrew = collectHomebrewConfigs cfg;
  };
}
