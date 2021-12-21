{ config, lib, pkgs, ... }:
{

  darwin.apps = {
    raycast.enable = true;
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
      "iterm2" # best terminal ever
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
