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

  storeSshKeyCmd = value: ''
    echo "${value}" | ${pkgs.openssl}/bin/openssl pkcs8 -topk8 -nocrypt | ssh-add -
  '';

  populateSecrets = namespace: variables: sshKeys:
    let
      opGetItem = vault: field: item: ''
        ${pkgs._1password}/bin/op read --session $token 'op://${vault}/${item}/${field}'
      '';

      syncOneVariable = key: item: ''
        echo >&2 "  Setting ${key} <- ${item.vault}.${item.item}.${item.field}"
        password=$(${opGetItem item.vault item.field item.item})
        ${storePasswordCmd namespace key "$password" "Password from ${item.vault}.${item.item}.${item.field}"}
      '';

      syncAllVariables = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneVariable items);

      syncOneKey = key: item: ''
        echo >&2 "  Adding ssh-key ${key} <- ${item.vault}.${item.item}.${item.field}"
        sshKey=$(${opGetItem item.vault item.field item.item})
        ${storeSshKeyCmd "$sshKey"}
      '';

      syncAllKeys = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneKey items);
    in
    pkgs.writeShellScript "populateKeys" ''
      set -e
      token=$(${pkgs._1password}/bin/op signin --raw)
      ${syncAllVariables variables}
      ${syncAllKeys sshKeys}
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

    sshKeys = mkOption {
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

  config = mkIf (cfg.enable && (cfg.sessionVariables != { } || cfg.sshKeys != { })) {
    home.activation.passwordsToKeychain = hm.dag.entryAfter [ "writeBoundary" ] ''
      noteEcho "Populating keychain from 1Password";
      $DRY_RUN_CMD ${populateSecrets cfg.namespace cfg.sessionVariables cfg.sshKeys}
    '';

    home.sessionVariables = lib.mapAttrs (k: v: ''$(${lookupPasswordCmd cfg.namespace k})'') cfg.sessionVariables;
  };
}
