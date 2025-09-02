{ pkgs, config, lib, ... }:

let
  vaultLoginScript = pkgs.writeShellScriptBin "vault-login" ''
NETWORKS=$(warp-cli vnet)

CURRENT_NETWORK=$(echo "$NETWORKS" | grep 'Currently selected' | awk '{print $NF}')

if [ -z "$CURRENT_NETWORK" ]; then
    echo "❌ You are currently not connected to any VPN. Please connect to a VPN using your Warp client"
    exit 1
fi

CURRENT_NETWORK_NAME=$(echo "$NETWORKS" | grep -A 1 "ID: $CURRENT_NETWORK" | grep 'Name:' | awk '{print $NF}')

if [[ $CURRENT_NETWORK_NAME =~ ^([^-]+)(-?([^-]+).*)?-vnet$ ]]; then
    if [ "''${BASH_REMATCH[1]}" == "live" ]; then
        BASE_DOMAIN="educationperfect.com"
        if [ -n "''${BASH_REMATCH[3]}" ]; then
            BASE_DOMAIN="''${BASH_REMATCH[3]}.''${BASE_DOMAIN}"
        fi
    else
        BASE_DOMAIN="educationperfect.io"

        if [ -n "''${BASH_REMATCH[3]}" ]; then
            BASE_DOMAIN="''${BASH_REMATCH[3]}.''${BASE_DOMAIN}"
        else
            BASE_DOMAIN="''${BASH_REMATCH[1]}.''${BASE_DOMAIN}"
        fi
    fi

else
    echo "❌ Unable to determine Vault domain URL for $CURRENT_NETWORK_NAME"
    exit 1
fi

VAULT_DOMAIN="vault.$BASE_DOMAIN"

echo "🔐 Logging in to Vault on $CURRENT_NETWORK_NAME: $VAULT_DOMAIN"
echo ""

export VAULT_ADDR="https://$VAULT_DOMAIN"

vault login -method=oidc -path=gsuite
  '';
in {
  home.packages = with pkgs; [
    vault
    vaultLoginScript
  ];
}
