{ config, pkgs, lib, ... }:
let
  username = builtins.getEnv "USER";
  homeDir = "/Users/${username}";
in
{
  imports = [
    <home-manager/nix-darwin>
    ./homebrew.nix
  ];

  # Fonts
  # fonts = {
  #   enableFontDir = true;
  #   fonts = [ pkgs.fira-code ];
  # };

  # homebrew.enable = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    nixUnstable
    nixpkgs-fmt
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Keyboard
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToControl = true;
  # };

  users.users.${username} = {
    name = username;
    home = homeDir;
  };

  home-manager.useUserPackages = true;
  home-manager.users.${username} = import ./home {
    inherit config;
    inherit pkgs;
    inherit lib;
    inherit username;
    inherit homeDir;
  };

  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;
  nix.package = pkgs.nixUnstable;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 12;
  nix.buildCores = 12;

  # nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

  nix.binaryCaches = [
    "https://cache.nixos.org/"
    "https://nix-tools.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nix.binaryCachePublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-tools.cachix.org-1:ebBEBZLogLxcCvipq2MTvuHlP7ZRdkazFSQsbs0Px1A="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
}


