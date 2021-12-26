{ config, lib, pkgs, ... }:
{

  darwin.apps = {
    raycast.enable = true;
    iterm2.enable = true; # best terminal ever
  };

  home-manager.users."${config.user.name}".home = {
    packages = with pkgs; [ m-cli ];
  };

  homebrew = {
    enable = true;

    taps = [
      "homebrew/cask"
      "homebrew/core"
    ];

    casks = [
      "1password"
      "brave-browser" # better chrome
      "discord"
      "docker"
      "dropbox"
      "licecap" # animated screenshots
      "openvpn-connect"
      "postman"
      "rider"
      "skype"
      "slack"
      "sublime-text"
      "visual-studio-code"
      "vlc"
      "zoom"
      "balenaetcher"

      "google-chrome"
    ];

    brews = [

    ];
  };
}
