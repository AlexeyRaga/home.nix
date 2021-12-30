{ ... }:

{
  # See https://github.com/LnL7/nix-darwin/tree/master/modules/system/defaults
  system.defaults = {

    # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/NSGlobalDomain.nix
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;

      # Configures the trackpad tab behavior. Mode 1 enables tap to click.
      "com.apple.mouse.tapBehavior" = 1;

      # Trackpad: map tap with two fingers to secondary click
      "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
      "com.apple.trackpad.enableSecondaryClick" = true;

      # Disable “natural” scrolling
      "com.apple.swipescrolldirection" = false;
    };

    # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/loginwindow.nix
    loginwindow = {
      GuestEnabled = false;
    };

    # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/trackpad.nix
    trackpad = {
      # Whether to enable trackpad tap to click. Default is false.
      Clicking = true;
      # Whether to enable trackpad right click. Default is false.
      TrackpadRightClick = true;
    };

    # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/finder.nix
    finder = {
      # Whether to show icons on the desktop or not. Default is true.
      CreateDesktop = false;
      # Whether to always show file extensions. Default is false.
      AppleShowAllExtensions = true;
      # Whether to show warnings when changing file extensions. Default is true.
      FXEnableExtensionChangeWarning = false;
    };

    # screencapture = {
    #   # The filesystem path to which screenshots should be written
    #   location = "~/Screenshots";
    # };

    # system.activationScripts.extraUserActivation.text = ''
    #   defaults write com.knollsoft.Rectangle gapSize -int 10
    #   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/Users/builditluc/wallpaper.png"'
    #   ln -sf ${pkgs.callPackage ./custom-pkgs/firefox { } }/Applications/Firefox.app /Applications
    # '';
  };
}
