{ ... }:

{
  # See https://github.com/LnL7/nix-darwin/tree/master/modules/system/defaults
  system.defaults = {

    # See https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/NSGlobalDomain.nix
    NSGlobalDomain = {
      # Configures the trackpad tab behavior. Mode 1 enables tap to click.
      "com.apple.mouse.tapBehavior" = 1;
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
  };
}
