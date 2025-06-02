{ config, lib, pkgs, appMode ? "install", appHelpers ? null, ... }:

with lib;

let
  cfg = config.brews.cloudflare-warp;
  # Import appHelpers if not provided as parameter
  helpers = if appHelpers != null then appHelpers else import ../../lib/app-helpers.nix { inherit lib; };

  writeScriptDir = path: text:
    pkgs.writeTextFile {
      inherit text;
      executable = true;
      name = builtins.baseNameOf path;
      destination = "${path}";
    };

  warpVnetShow = pkgs.writeShellScriptBin "warp-show" ''
warp-cli status | grep -q "Disconnected" && exit 0 || true

CURRENT_NETWORK_NAME=$(warp-cli --json vnet | jq -r '. as $data | $data.virtual_networks[] | select(.id == $data.active_vnet_id) | .name')

echo $CURRENT_NETWORK_NAME
  '';

  warpSwitch = pkgs.writeShellScriptBin "warp-switch" ''
    case "''${1,,}" in
      "" | "help" | "--help" | "-h" | "-help" | "/?" | "/help")
        cat << EOF
Usage: warp-switch [network_name | off]

Switch between VPN networks or turn off the VPN.

Arguments:
  network_name   Specify the name of the network to switch to.
                 Example: warp-switch reporting-vnet

  off            Turn off the VPN.
                 Example: warp-switch off
EOF
      ;;
      off)
        warp-cli disconnect > /dev/null
        ;;
      *)
        warp-cli --json vnet | jq -r --arg PREFIX "$1" '.virtual_networks[] | select(.name == $PREFIX or .name == ($PREFIX + "-vnet")) | .id' | head -n 1 | xargs warp-cli vnet
        warp-cli connect > /dev/null
        ;;
    esac
  '';

  warpSwitchCompletion = writeScriptDir "/share/zsh/site-functions/_warp-switch" ''
    #compdef warp-switch
    _warp_cli_get_virtual_networks() {
      local -a subnet_names
      subnet_names=($(warp-cli --json vnet | jq -r '.virtual_networks[].name' | grep -v "default"))
      compadd $subnet_names
    }

    compdef _warp_cli_get_virtual_networks warp-switch
  '';
in
{
  options.brews.cloudflare-warp = { 
    enable = mkEnableOption "Enable Cloudflare Warp"; 
  };

  config = mkIf cfg.enable (
    helpers.modeSwitchMap appMode {
      # Install mode: Darwin/homebrew configuration
      install = {
        homebrew = {
          casks = [ "cloudflare-warp" ];
        };

        environment.systemPackages = [
          warpSwitch
          warpVnetShow
          warpSwitchCompletion
        ];

        environment.variables = {

        };
      };

      # Configure mode: Home-manager configuration  
      configure = {};
    }
  );
}
