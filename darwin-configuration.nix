{ config, pkgs, lib, ... }:
let
  modules = import ./lib/modules.nix {inherit lib;};
in
{
  imports = [
    ./users.nix
    <home-manager/nix-darwin>
  ] ++ (modules.importAllModules ./darwin);

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  users.users.${config.user.name} = {
    name = config.user.name;
    home = config.user.home;
  };

  home-manager.useUserPackages = true;
  home-manager.users.${config.user.name} = import ./home {
    inherit config;
    inherit pkgs;
    inherit lib;
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


