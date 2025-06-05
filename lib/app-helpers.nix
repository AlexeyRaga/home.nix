{ lib }:

with lib;

{
  # Mode-switching helper that takes a mode and a mapping of mode -> config
  # Returns the appropriate config based on mode
  modeSwitchMap = mode: configMap:
    let
      validModes = attrNames configMap;
    in
    if hasAttr mode configMap then configMap.${mode}
    else throw "Invalid appMode: ${mode}. Valid modes: ${concatStringsSep ", " validModes}";

  # Alternative simpler function for just install/configure
  modeSwitch = mode: installConfig: configureConfig:
    if mode == "install" then installConfig
    else if mode == "configure" then configureConfig  
    else throw "Invalid appMode: ${mode}. Must be 'install' or 'configure'";

  # Define the standard modes as constants
  modes = {
    install = "install";     # Darwin/homebrew context
    configure = "configure"; # Home-manager context
  };
}
