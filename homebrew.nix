{ inputs, config, pkgs, ... }:
let
  brewBinPrefix = if pkgs.system == "aarch64-darwin" then "/opt/homebrew/bin" else "/usr/local/bin";
in
{
  homebrew = {
    enable = true;
    brewPrefix = brewBinPrefix;
    autoUpdate = true;
    cleanup = "zap";
    global.brewfile = true;
    global.noLock = true;

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
      "postman"
      "rider"
      "raycast" # better spotlight
      "skype"
      "slack"
      "sublime-text"
      "visual-studio-code"
      "vlc"
      "zoom"
    ];

    brews = [

    ];
  };
}
