{ config, pkgs, ... }:

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
    # docker
    # docker-machine
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Keyboard
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToControl = true;
  # };

  users.users.alexey = {
    name = "alexey";
    home = "/Users/alexey";
  };

  home-manager.useUserPackages = true;
  home-manager.users.alexey = { pkgs, ... }: { imports = [ ./home ]; };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = false;
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
  ];
}


