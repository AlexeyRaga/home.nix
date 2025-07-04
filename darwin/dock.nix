{ config, lib, pkgs, user, ... }:
{
  system.defaults.dock = {
    # Whether to automatically hide and show the Dock. Default is false.
    autohide = false;
    # Sets the speed of the autohide delay. Default is "0.24".
    autohide-delay = 0.0;
    # Sets the speed of animation when hiding/showing the Dock. Default is "1.0".
    autohide-time-modifier = 1.0;
    # Position of dock. Default is "bottom"; alternatives are "left" and "right".
    orientation = "bottom";
    # Whether to make icons of hidden applications translucent. Default is false.
    showhidden = true;
    # Show recent applications in the dock. Default is true.
    show-recents = false;
    # Show only open applications in the Dock. Default is false.
    static-only = false;
    # Size of the icons in the Dock. Default is 64.
    tilesize = 32;

    persistent-apps = [
      { app = "/Applications/Brave Browser.app"; }
      { app = "/Applications/Rider.app"; }
      { app = "/Applications/Visual Studio Code.app"; }
      { app = "/Applications/iTerm.app"; }
      { app = "/Applications/Slack.app"; }
      { app = "/Applications/Telegram.app"; }
      { app = "/Applications/Discord.app"; }
    ];

    persistent-others = [ "/Applications" "${user.home}/Downloads" ];
  };
}

