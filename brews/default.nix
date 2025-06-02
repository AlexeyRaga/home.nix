{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

let
  modules = import ../lib/modules.nix {inherit lib;};
in
{
  imports = [ ./apps.nix ] ++ (modules.importAllModules appMode ./modules);
}
