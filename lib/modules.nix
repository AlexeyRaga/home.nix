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
  # Map every module inside dir.
  # mapModules :: path -> (path -> any) -> attrs
  mapModules = dir: fn:
    mapFilterAttrs
      (n: v: v != null && !(hasPrefix "_" n))
      (
        n: v:
          let path = "${dir}/${n}";
          in
          if v == "directory" && pathExists "${path}/default.nix"
          then nameValuePair n (fn path)
          else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
          then nameValuePair (removeSuffix ".nix" n) (fn path)
          else nameValuePair "" null
      )
      (readDir dir);

  # Map every module inside dir, returning a list of the results.
  # mapModules' :: path -> (path -> any) -> [any]
  mapModules' = dir: fn: attrValues (mapModules dir fn);

  # Recursively map every module inside dir.
  # mapModulesRec :: (path) -> (path -> any) -> attrs
  mapModulesRec = dir: fn:
    mapFilterAttrs
      (n: v: v != null && !(hasPrefix "_" n))
      (
        n: v:
          let path = "${dir}/${n}";
          in
          if v == "directory" && pathExists "${path}/default.nix"
          then nameValuePair n (mapModulesRec path fn)
          else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
          then nameValuePair (removeSuffix ".nix" n) (fn path)
          else nameValuePair "" null
      )
      (readDir dir);

  # Recursively map every module inside dir, returning a list of the results.
  # mapModulesRec :: (path) -> (path -> any) -> [any]
  mapModulesRec' = dir: fn:
    let
      dirs = mapAttrsToList (k: _: "${dir}/${k}")
        (filterAttrs (n: v: v == "directory" && !(hasPrefix "_" n)) (readDir dir));
      files = attrValues (mapModules dir id);
      paths = files ++ concatLists (map (d: mapModulesRec' d id) dirs);
    in
    map fn paths;

  importAllModules = dir: mapModulesRec' dir import;
}
