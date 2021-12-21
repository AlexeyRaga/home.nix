{ config, lib, pkgs, ... }:
{
  imports = [
    ./homebrew.nix
    ./plists.nix
    ./dock-apps.nix
  ];
}
