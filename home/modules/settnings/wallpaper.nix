{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.home.wallpaper;
  setWallpaper = file:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''osascript -e 'tell application "Finder" to set desktop picture to POSIX file "${file}"' ''
    else
      ''echo "Unable to set wallpaper on ${pkgs.stdenv.hostPlatform.system}"'';
in
{
  options.home.wallpaper.file = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Path to image for wallpaper";
  };

  config = mkIf (cfg.file != null) {
    home.activation = {
      setDarwinWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${setWallpaper cfg.file}
      '';
    };
  };
}
