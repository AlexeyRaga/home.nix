{ config, lib, pkgs, ... }:

{
  # App configurations are now in brews/shared-config.nix and imported automatically

  darwin.apps = {
    raycast.enable = true;
    magnet = {
      enable = true;

      commands = [
        {
          name = "Top Left Two Thirds";
          id = "D902DA03-47FB-40D5-8015-3499A9EB167E";
          shortcut = [ "Cmd" "CTRL" "." ];
          targetArea = {
            area = {
              segments = [
                {
                  id = "5DD6FE34-866B-4127-9219-346433F8AAA1";
                  frame = [ [0 0] [8 8] ];
                }
              ];
            };
          };
        }
      ];
    };
  };

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
