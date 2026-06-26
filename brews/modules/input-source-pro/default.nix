{ config, lib, pkgs, user ? {}, ... }:

with lib;

let
  cfg = config.brews.input-source-pro;

  # Settings exported from Input Source Pro, kept next to this module. Becomes a
  # content-addressed store path that we hand to the import URL scheme below.
  settings = ./settings.json;

in
{
  options.brews.input-source-pro = {
    enable = mkEnableOption "Enable Input Source Pro";
  };

  systemConfig = mkIf cfg.enable {
    # Install mode: Darwin/homebrew configuration
    homebrew = {
      casks = [ "input-source-pro" ];
    };
  };

  userConfig = mkIf cfg.enable {
    # Import the bundled settings through the scriptable URL scheme added in
    # https://github.com/runjuu/InputSourcePro/commit/a4c6f1b56e06f5da66bc8b9d8d22c6e4596b1dbb
    #   inputsourcepro://import?path=<absolute>&silent=1
    #
    # The import is destructive: it *replaces* the supported settings, rules,
    # color configs, hot key groups, and recorded shortcuts (there is no additive
    # mode). So we import only once — on first run — and drop a marker afterwards.
    # Later rebuilds leave the app alone even if settings.json changes, so any
    # in-app tweaks survive. Delete the marker to force a re-import next rebuild.
    home.activation.configureInputSourcePro = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      marker="$HOME/.config/input-source-pro/imported"
      app="/Applications/Input Source Pro.app"
      lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

      if [ ! -e "$marker" ]; then
        echo "Input Source Pro: first-run settings import"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$marker")"

        # On a fresh machine LaunchServices may not have indexed the just-installed
        # cask yet, so the inputsourcepro:// scheme would not resolve. Force-register
        # the app first (skipped if the cask is not installed yet).
        if [ -d "$app" ]; then
          $DRY_RUN_CMD "$lsregister" -f "$app"
        fi

        # Write the marker only on a successful import, so a first run that fails
        # (e.g. cask not installed yet) is retried on the next rebuild.
        if $DRY_RUN_CMD /usr/bin/open "inputsourcepro://import?path=${settings}&silent=1"; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/touch "$marker"
          echo "Input Source Pro: imported. Delete $marker to re-import."
        else
          echo "Input Source Pro: import failed; will retry next rebuild" >&2
        fi
      fi
    '';
  };
}