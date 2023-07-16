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
      "cheatsheet"
      "cloudflare-warp"
      "discord"
      "dropbox"
      "google-chrome"
      "jetbrains-toolbox"
      "licecap" # animated screenshots
      "openvpn-connect"
      "postman"
      "rancher"
      "rider"
      "skype"
      "slack"
      "sublime-text"
      "telegram"
      "visual-studio-code"
      "vlc"
      "warp" # new terminal
      "zoom"
    ];

    brews = [

    ];

    masApps = {
      Magnet = 441258766;
    };
  };
}
