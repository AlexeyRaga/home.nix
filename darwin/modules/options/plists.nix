{ config, lib, pkgs, ... }:

with lib;

let
  enabled = pkgs.hostPlatform.isDarwin;
  cfg = config.targets.darwin.plists;

in
{
  options.targets.darwin.plists = mkOption {
    description = "Edits to plists to be made via PlistBuddy";
    type = types.attrsOf types.attrs;
    default = {};
  };

  config = mkIf (enabled && cfg != {}) {
    system.activationScripts.postUserActivation.text =
      let
        enquote = str: "'" + lib.strings.removeSuffix "'" (lib.strings.removePrefix "'" str) + "'";
        wrapPath = str: builtins.concatStringsSep ":" (map enquote (lib.strings.splitString ":" str));
        toValue = obj: if isBool obj then boolToString obj else obj;

        toCmd = file: path: value: ''
          $DRY_RUN_CMD /usr/libexec/PlistBuddy -c "Set ${wrapPath path} ${toValue value}" $HOME/${file}
        '';
        toCmds = file: settings: concatStrings (mapAttrsToList (toCmd file) settings);
      in
      ''
        ${concatStrings (mapAttrsToList toCmds cfg)}
      '';
  };
}
