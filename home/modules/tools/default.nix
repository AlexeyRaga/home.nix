{ pkgs, config, lib, ... }:
{
  imports = [
    ./aws.nix
    ./dotnet.nix
    ./git.nix
    ./haskell.nix
  ];
}
