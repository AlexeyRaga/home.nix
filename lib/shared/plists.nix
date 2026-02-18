{ lib, pkgs }:
let
  mergeJsonTool = pkgs.writeShellApplication {
    name = "merge-plist-json";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      if [ $# -ne 3 ]; then
        echo "usage: merge-plist-json <target.plist> <keyPath-json> <source-json>" >&2
        exit 2
      fi
      exec ${pkgs.python3.interpreter} - "$@" << 'EOF'
import sys, json, plistlib

target_path, keypath_json, source_json = sys.argv[1:4]

with open(target_path, 'rb') as f: target = plistlib.load(f)
source = json.loads(source_json)
keypath = json.loads(keypath_json)

def ensure_path(obj, path):
    """Navigate to target location, creating structure as needed. Returns (parent, final_key)."""
    if not path: return None, None
    current = obj
    for key in path[:-1]:
        if isinstance(key, int):
            if not isinstance(current, list): current = []
            while len(current) <= key: current.append({})
            if not isinstance(current[key], (dict, list)): current[key] = {}
            current = current[key]
        else:
            if not isinstance(current, dict): current = {}
            if key not in current: current[key] = {}
            current = current[key]
    return current, path[-1]

def deep_merge(dst, src):
    """Recursively merge src into dst."""
    if isinstance(dst, dict) and isinstance(src, dict):
        for k, v in src.items():
            dst[k] = deep_merge(dst.get(k), v) if k in dst and isinstance(dst[k], dict) and isinstance(v, dict) else v
        return dst
    return src

parent, final_key = ensure_path(target, keypath)
if parent is None:  # Empty keypath - merge at root
    target = deep_merge(target, source) if isinstance(target, dict) and isinstance(source, dict) else source
else:
    if isinstance(final_key, int):
        if not isinstance(parent, list): parent = []
        while len(parent) <= final_key: parent.append({})
        parent[final_key] = deep_merge(parent[final_key], source) if isinstance(parent[final_key], dict) and isinstance(source, dict) else source
    else:
        if not isinstance(parent, dict): parent = {}
        parent[final_key] = deep_merge(parent.get(final_key), source) if final_key in parent and isinstance(parent[final_key], dict) and isinstance(source, dict) else source

with open(target_path, 'wb') as f: plistlib.dump(target, f)
EOF
    '';
  };

  # Thin wrapper: converts the source plist to JSON, then delegates to mergeJsonTool
  mergePlistTool = pkgs.writeShellApplication {
    name = "merge-plist";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      if [ $# -ne 3 ]; then
        echo "usage: merge-plist <target.plist> <keyPath-json> <source.plist>" >&2
        exit 2
      fi
      source_json=$(${pkgs.python3.interpreter} -c 'import sys,json,plistlib;sys.stdout.write(json.dumps(plistlib.load(open(sys.argv[1],"rb"))))' "$3")
      exec ${mergeJsonTool}/bin/merge-plist-json "$1" "$2" "$source_json"
    '';
  };

in rec {
  # Merge a source plist file into target at the specified keyPath
  merge = target: keyPath: source:
    "${mergePlistTool}/bin/merge-plist ${lib.escapeShellArgs [target (builtins.toJSON keyPath) source]}";

  # Merge a raw JSON string into target at the specified keyPath
  mergeJson = target: keyPath: jsonString:
    "${mergeJsonTool}/bin/merge-plist-json ${lib.escapeShellArgs [target (builtins.toJSON keyPath) jsonString]}";

  # Merge a Nix value (attrset, list, string, number, bool) into target at the specified keyPath
  mergeValue = target: keyPath: value:
    mergeJson target keyPath (builtins.toJSON value);
}
