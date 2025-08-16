{ config, pkgs, lib, user, ... }:
let
  modules = import ./lib/modules.nix {inherit lib;};
in
{
  documentation.enable = false;
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = user.name;

  nixpkgs.overlays = [
    # sometimes it is useful to pin a version of some tool or program.
    # this can be done in "overlays/pinned.nix"
    (import ./overlays/pinned.nix)
  ];

  imports = [
    ./certificates.nix
    ./brews/apps.nix
  ] ++ (modules.importAllModules ./darwin) ++ (modules.importDarwinModules ./brews);


  programs.zsh.enable = true;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  environment = {
    shells = [ pkgs.zsh ];
    systemPackages = [ pkgs.nixpkgs-fmt ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
  ids.gids.nixbld = 30000;

  # nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;

  # set up current user
  users.users.${user.name} = {
    name = user.name;
    home = user.home;
  };

  homebrew = {
    enable = true;

    global.brewfile = true;
    onActivation.cleanup = "zap";
  };

  nix = {
    # package = pkgs.nix;
    package = pkgs.nixVersions.latest;

    settings = {
      max-jobs = 12;

      # $ sysctl -n hw.ncpu
      cores = 12;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-tools.cachix.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];

      trusted-users = [
        user.name
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-tools.cachix.org-1:ebBEBZLogLxcCvipq2MTvuHlP7ZRdkazFSQsbs0Px1A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };
}


