### Home-manager entrypoint for standalone mode.
### Only makes sense for "typical" Linux distributions
### (not NixOS or Darwin)

{ config, pkgs, lib, ... }:
{
  imports = [
    ./users.nix
    ./home
  ];
}

