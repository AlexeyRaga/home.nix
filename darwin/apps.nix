{ config, lib, pkgs, ... }:

{
  # App configurations are now in brews/shared-config.nix and imported automatically

  homebrew = {
    enable = true;

    casks = [
      "1password"
      "brave-browser" # better chrome
      "cheatsheet"
      "cursor"
      "discord"
      "dropbox"
      "google-chrome"
      "iina" # modern video player
      "jetbrains-toolbox"
      "intellij-idea"
      "datagrip"
      "licecap" # animated screenshots
      "notion"
      "notion-calendar"
      "postman"
      "hoppscotch" # postman alternative
      "rider"
      "shottr" # screenshot tool
      "skype"
      "slack"
      "sublime-text"
      "telegram"
      "vlc"
      "warp" # AI-enabled terminal
      "zoom"
      "zed" # code editor
      "mitmproxy"
    ];

    brews = [

    ];


    global.brewfile = true;
    onActivation.cleanup = "zap";

    taps = [
    ];
  };
}
