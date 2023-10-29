{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.darwin.apps.cloudflare-warp;

  writeScriptDir = path: text:
    pkgs.writeTextFile {
      inherit text;
      executable = true;
      name = builtins.baseNameOf path;
      destination = "${path}";
    };

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
        warp-cli get-virtual-networks | grep -B1 "Name: $1" | head -n 1 | cut -d' ' -f2 | xargs warp-cli set-virtual-network
        warp-cli connect > /dev/null
        ;;
    esac
  '';

  warpSwitchCompletion = writeScriptDir "/share/zsh/site-functions/_warp-switch" ''
    #compdef warp-switch
    _warp_cli_get_virtual_networks() {
      local -a subnet_names
      subnet_names=($(warp-cli get-virtual-networks | grep 'Name: ' | cut -d' ' -f2 | grep -v "default"))
      compadd $subnet_names
    }

    compdef _warp_cli_get_virtual_networks warp-switch
  '';
in
{
  options.darwin.apps.cloudflare-warp = { enable = mkEnableOption "Enable Cloudflare Warp"; };

  config = mkIf enabled {
    homebrew = {
      casks = [ "cloudflare-warp" ];
    };

    environment.systemPackages = [
      warpSwitch
      warpSwitchCompletion
      ];

    environment.variables = {

    };

  };
}
