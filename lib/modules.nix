{ lib, ... }:

with builtins;
with lib;

let
  # Maps and filters attributes
  # mapFilterAttrs :: (name -> value -> bool)
  #                -> (name -> value -> { name = any; value = any; })
  #                -> attrs
  #                -> attrs
  mapFilterAttrs = pred: f: attrs: filterAttrs pred (mapAttrs' f attrs);
in
rec {
  # Auto-discover and import shared libraries from lib/shared directory
  # discoverSharedLibs :: lib -> pkgs -> attrs
  discoverSharedLibs = lib: pkgs:
    let
      sharedLibDir = ./shared;
    in
    if pathExists sharedLibDir then
      mapModules sharedLibDir (libPath: import libPath { inherit lib pkgs; })
    else {};

  # Map every module inside dir.
  # mapModules :: path -> (path -> any) -> attrs
  mapModules = dir: fn:
    mapFilterAttrs
      (n: v: v != null)
      (
        n: v:
          let path = dir + "/${n}";
          in
          if v == "directory" && pathExists (path + "/default.nix")
          then nameValuePair n (fn path)
          else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
          then nameValuePair (removeSuffix ".nix" n) (fn path)
          else nameValuePair "" null
      )
      (readDir dir);

  # Recursively map every module inside dir, returning a flat list of the
  # results. A directory with a default.nix is a leaf module (recursion stops);
  # default.nix-less directories are namespaces we recurse into.
  # mapModulesRec :: path -> (path -> any) -> [any]
  mapModulesRec = dir: fn:
    let
      # A directory with its own default.nix is a self-contained module: it
      # stops recursion (like mapModules), so sibling .nix files inside it
      # (e.g. package.nix) are NOT imported as separate modules. Only
      # default.nix-less directories are treated as namespaces to recurse into.
      dirs = mapAttrsToList (k: _: dir + "/${k}")
        (filterAttrs
          (n: v: v == "directory"
                 && !(pathExists (dir + "/${n}/default.nix")))
          (readDir dir));
      files = attrValues (mapModules dir id);
      paths = files ++ concatLists (map (d: mapModulesRec d id) dirs);
    in
    map fn paths;
  
  # Auto-discover and compose overlays from a directory (recursively)
  # discoverOverlays :: path -> [overlay]
  discoverOverlays = dir:
    if pathExists dir then
      mapModulesRec dir (path: import path)
    else [];
  
  # New dual-context import functions
  # Import modules for darwin context (uses 'systemConfig' section)
  importDarwinModules = dir: 
    mapModulesRec dir (path: 
      { config, lib, pkgs, user ? {}, ... }@args:
        let
          # Auto-discover shared libraries and extend lib with them
          sharedLibs = discoverSharedLibs lib pkgs;
          extendedLib = lib.extend (final: prev: sharedLibs);
          
          # Use extended lib in module arguments
          moduleArgs = args // { lib = extendedLib; };
          moduleResult = import path moduleArgs;
        in
        {
          options = moduleResult.options or {};
          config = moduleResult.systemConfig or moduleResult.config
                   or (if moduleResult ? options then {} else moduleResult);
        }
    );

  # Import modules for home-manager context (uses 'userConfig' section)  
  importHomeModules = dir:
    mapModulesRec dir (path:
      { config, lib, pkgs, user ? {}, ... }@args:
        let
          # Auto-discover shared libraries and extend lib with them
          sharedLibs = discoverSharedLibs lib pkgs;
          extendedLib = lib.extend (final: prev: sharedLibs);
          
          # Use extended lib in module arguments
          moduleArgs = args // { lib = extendedLib; };
          moduleResult = import path moduleArgs;
        in
        {
          options = moduleResult.options or {};
          config = moduleResult.userConfig or moduleResult.config
                   or (if moduleResult ? options then {} else moduleResult);
        }
    );
}
