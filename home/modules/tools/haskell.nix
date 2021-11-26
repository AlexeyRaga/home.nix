{ config, lib, pkgs, ... }:

{
  home.sessionPath = [
    "$HOME/.cabal/bin"
    "$HOME/.ghcup/bin"
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
  ];
}
