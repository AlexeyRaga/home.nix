/* Global MacOS configuration using nix-darwin (https://github.com/LnL7/nix-darwin).
 * Sets up minimal required system-level configuration, such as
 * Darwin-specific modules, certificates, etc.
 *
 * Also enables Home Manager.
 * Home Manager is used for the rest of user-level configuration.
 * Home Manager configuratio is located in ./home folder.
 */
{ config, pkgs, lib, ... }:
let
  modules = import ./lib/modules.nix {inherit lib;};
in
{
  documentation.enable = false;

  nixpkgs.overlays = [
    # sometimes it is useful to pin a version of some tool or program.
    # this can be done in "overlays/pinned.nix"
    (import ./overlays/pinned.nix)
  ];


  imports = [
    ./certificates.nix
    ./users.nix
    <home-manager/nix-darwin>
  ] ++ (modules.importAllModules ./darwin);

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];
    systemPackages = [
      pkgs.nixpkgs-fmt
      # (import (fetchTarball https://github.com/cachix/devenv/archive/v0.5.tar.gz)).default
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # set up current user
  users.users.${config.user.name} = {
    name = config.user.name;
    home = config.user.home;
  };

  # and enable home manager for the current user
  home-manager = {
    useUserPackages = true;
    users.${config.user.name} = import ./home {
      inherit config;
      inherit pkgs;
      inherit lib;
    };
  };

  services = {
    nix-daemon.enable = true;
    # Recreate /run/current-system symlink after boot.
    activate-system.enable = true;
  };

  # nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;

  nix = {
    # package = pkgs.nix;
    package = pkgs.nixUnstable;

    settings = {
      max-jobs = 12;

      # $ sysctl -n hw.ncpu
      cores = 12;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-tools.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-tools.cachix.org-1:ebBEBZLogLxcCvipq2MTvuHlP7ZRdkazFSQsbs0Px1A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}


