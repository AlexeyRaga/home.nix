{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.secureEnv.onePassword;

  storePasswordCmd = namespace: key: value: comment:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''security add-generic-password -U -a ${namespace} -s ${key} -w "${value}" -j "${comment}"''
    else
      ''echo "${value}" | ${pkgs.libsecret}/bin/secret-tool store --label='${comment}' namespace '${namespace}' key '${key}' '';

  lookupPasswordCmd = namespace: key:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''security find-generic-password -w -s '${key}' -a '${namespace}' ''
    else
      ''${pkgs.libsecret}/bin/secret-tool lookup namespace '${namespace}' key '${key}' '';


  populateSecrets = namespace: values:
    let
      syncOne = key: item: ''
        echo >&2 "  Setting ${key} <- ${item.vault}.${item.item}.${item.field}"
        password=$(${pkgs._1password}/bin/op get item --session $token --vault ${item.vault} --fields '${item.field}' '${item.item}')
        ${storePasswordCmd namespace key "$password" "Password from ${item.vault}.${item.item}.${item.field}"}
      '';

      syncAll = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOne items);
    in
    pkgs.writeShellScript "populateKeys" ''
      set -e
      token=$(${pkgs._1password}/bin/op signin --raw)
      ${syncAll values}
    '';
in
{
  options.secureEnv.onePassword = {
    enable = mkEnableOption "Enable populating keychain";

    namespace = mkOption {
      type = types.str;
      default = "nixConfig";
      description = "Namespace for keychain entries (displays as 'account' in Keychain)";
    };

    sessionVariables = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          vault = mkOption { type = types.str; };
          item = mkOption { type = types.str; };
          field = mkOption { type = types.str; };
        };
      });
      default = { };
    };
  };

  config = mkIf (cfg.enable && cfg.sessionVariables != { }) {
    home.activation.passwordsToKeychain = hm.dag.entryAfter [ "writeBoundaty" ] ''
      noteEcho "Populating keychain from 1Password";
      $DRY_RUN_CMD ${populateSecrets cfg.namespace cfg.sessionVariables}
    '';

    home.sessionVariables = lib.mapAttrs (k: v: ''$(${lookupPasswordCmd cfg.namespace k})'') cfg.sessionVariables;
  };
}
