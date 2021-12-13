{ pkgs, config, lib, ... }:

with lib;

let
  homeDir = config.home.homeDirectory;
  cfg = config.keychain;

  toOpGetCommand = namespace: key: item: ''
    echo >&2 "  Setting ${key} <- ${item.vault}.${item.item}.${item.field}"
    password=$(${pkgs._1password}/bin/op get item --session $token --vault ${item.vault} --fields ${item.field} ${item.item})
    security add-generic-password -U -a ${namespace} -s ${key} -w $password -j "Value from 1Password: ${item.vault}.${item.item}.${item.field}"
  '';

  allCommands = namespace: items:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (toOpGetCommand namespace) items);

  script = namespace: keys: pkgs.writeShellScript "populateKeys" ''
    set -e
    token=$(${pkgs._1password}/bin/op signin --raw)
    ${allCommands namespace keys}
  '';

in
{
  options.keychain = {
    enable = mkEnableOption "Enable populating keychain";

    namespace = mkOption {
      type = types.str;
      default = "nixConfig";
      description = "Namespace for keychain entries (displays as 'account' in Keychain)";
    };

    from1Password = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          vault = mkOption { type = types.str; };
          item = mkOption { type = types.str; };
          field = mkOption { type = types.str; };
        };
      });
      default = {};
    };
  };

  config = mkIf  (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin && cfg.from1Password != {}) {
    home.activation.passwordsToKeychain = hm.dag.entryAfter ["writeBoundaty"] ''
        noteEcho "Populating keychain from 1Password";
        $DRY_RUN_CMD ${script cfg.namespace cfg.from1Password}
      '';
  };
}
