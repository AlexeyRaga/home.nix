{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.secureEnv.onePassword;
  requiredPackages = with pkgs; [ _1password-cli ];

  storeSecret = namespace: key: value: comment:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''/usr/bin/security add-generic-password -U -a ${namespace} -s ${key} -w "${value}" -j "${comment}"''
    else
      ''echo "${value}" | ${pkgs.libsecret}/bin/secret-tool store --label='${comment}' namespace '${namespace}' key '${key}' '';

  lookupSecret = namespace: key:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''/usr/bin/security find-generic-password -w -s '${key}' -a '${namespace}' ''
    else
      ''${pkgs.libsecret}/bin/secret-tool lookup namespace '${namespace}' key '${key}' '';

  storeSshKeyCmd = value: ''
    echo "${value}" | ${pkgs.openssl}/bin/openssl pkcs8 -topk8 -nocrypt | ssh-add -
  '';

  populateSecrets = nsConfig:
    let
      opGetItem = account: vault: field: item: ''
        ${pkgs._1password-cli}/bin/op read --account '${account}' 'op://${vault}/${item}/${field}'
      '';

      syncOneVariable = key: item: ''
        echo >&2 "  Setting ${key} <- ${item.account}/${item.vault}/${item.item}/${item.field}"
        password=$(${opGetItem item.account item.vault item.field item.item})
        ${storeSecret "nix-1pwd" key "$password" "Password from ${item.vault}.${item.item}.${item.field}"}
      '';

      syncAllVariables = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneVariable items);

      syncOneKey = key: item: ''
        echo >&2 "  Adding ssh-key ${key} <- ${item.account}/${item.vault}/${item.item}/${item.field}"
        sshKey=$(${opGetItem item.account item.vault item.field item.item})
        ${storeSshKeyCmd "$sshKey"}
      '';

      syncAllKeys = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneKey items);
    in
    pkgs.writeShellScript "populateKeys" ''
      set -e
      ${syncAllVariables nsConfig.sessionVariables}
      ${syncAllKeys nsConfig.sshKeys}
      ${pkgs._1password-cli}/bin/op signout --all
    '';
in
{  options.secureEnv.onePassword = {
    enable = mkEnableOption "Enable populating keychain";

    sessionVariables = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          account = mkOption { type = types.str; };
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
          account = mkOption { type = types.str; };
          vault = mkOption { type = types.str; };
          item = mkOption { type = types.str; };
          field = mkOption { type = types.str; };
        };
      });
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = requiredPackages;

    home.activation.passwordsToKeychain = hm.dag.entryAfter [ "writeBoundary" ] ''
      # Set TERM to avoid tput errors during activation
      export TERM="${TERM:-dumb}"
      noteEcho "Populating keychain from 1Password";
      $DRY_RUN_CMD ${populateSecrets cfg}
    '';

    home.sessionVariables = lib.mapAttrs' (k: v: lib.nameValuePair k ''$(${lookupSecret "nix-1pwd" k})'') cfg.sessionVariables;
  };
}
