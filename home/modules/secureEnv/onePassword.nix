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
      opGetItem = account: vault: field: item: 
        "${pkgs._1password-cli}/bin/op read --account '${account}' 'op://${vault}/${item}/${field}'";

      syncOneVariable = key: item: ''
        echo >&2 "  Setting ${key} <- ${item.account}/${item.vault}/${item.item}/${item.field}"
        if password=$(${opGetItem item.account item.vault item.field item.item} 2>/dev/null); then
          ${storeSecret "nix-1pwd" key "$password" "Password from ${item.vault}.${item.item}.${item.field}"}
        else
          ${if item.required then ''
            echo >&2 "    ✗ ERROR: Failed to retrieve required secret ${key}"
            echo >&2 "      This may be due to:"
            echo >&2 "      - Not signed in to 1Password (run 'op signin')"
            echo >&2 "      - Missing access to vault '${item.vault}'"
            echo >&2 "      - Item '${item.item}' or field '${item.field}' doesn't exist"
            echo >&2 "    Make sure that 1Password Desktop app is running."
            exit 1
          '' else ''
            echo >&2 "    ⚠ WARNING: Failed to retrieve optional secret ${key}, skipping"
          ''}
        fi
      '';

      syncAllVariables = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneVariable items);

      syncOneKey = key: item: ''
        echo >&2 "  Adding ssh-key ${key} <- ${item.account}/${item.vault}/${item.item}/${item.field}"
        if sshKey=$(${opGetItem item.account item.vault item.field item.item} 2>/dev/null); then
          ${storeSshKeyCmd "$sshKey"}
        else
          ${if item.required then ''
            echo >&2 "    ✗ ERROR: Failed to retrieve required SSH key ${key}"
            echo >&2 "      This may be due to:"
            echo >&2 "      - Not signed in to 1Password (run 'op signin')"
            echo >&2 "      - Missing access to vault '${item.vault}'"
            echo >&2 "      - Item '${item.item}' or field '${item.field}' doesn't exist"
            echo >&2 "    Make sure that 1Password Desktop app is running."
            exit 1
          '' else ''
            echo >&2 "    ⚠ WARNING: Failed to retrieve optional SSH key ${key}, skipping"
          ''}
        fi
      '';

      syncAllKeys = items: lib.concatStringsSep "\n" (lib.mapAttrsToList syncOneKey items);
    in
    pkgs.writeShellScript "populateKeys" ''
      set -e
      echo >&2 "Syncing secrets from 1Password..."
      ${syncAllVariables nsConfig.sessionVariables}
      ${syncAllKeys nsConfig.sshKeys}
      ${pkgs._1password-cli}/bin/op signout --all
      echo >&2 "✓ 1Password sync completed"
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
          required = mkOption {
            type = types.bool;
            default = true;
            description = "Whether missing this secret should fail activation";
          };
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
          required = mkOption {
            type = types.bool;
            default = true;
            description = "Whether missing this SSH key should fail activation";
          };
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

    # Only set up session variables for secrets that exist in keychain
    # The populateSecrets script only stores secrets it successfully retrieves
    home.sessionVariables = lib.mapAttrs' 
      (k: v: lib.nameValuePair k ''$(${lookupSecret "nix-1pwd" k} 2>/dev/null || echo "")'') 
      cfg.sessionVariables;
  };
}
