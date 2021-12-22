{ config, options, lib, pkgs, ... }:

with lib; {
  options = with types; { user = mkOption { type = attrs; default = { }; }; };

  config = {
    user =
      let
        name = builtins.getEnv "USER";
        home = builtins.getEnv "HOME";
      in
      {
        inherit name;
        inherit home;
      };
  };
}
