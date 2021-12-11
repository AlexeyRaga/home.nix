### Home-manager entrypoint for standalone mode.
### Only makes sense for "typical" Linux distributions
### (not NixOS or Darwin)

{ config, pkgs, lib, ... }:
let
  username = builtins.getEnv "USER";
  homeDir = "/Users/${username}";
in
  import ./home {
    inherit config;
    inherit pkgs;
    inherit lib;
    inherit username;
    inherit homeDir;
  }
