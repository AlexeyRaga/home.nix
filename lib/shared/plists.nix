{ lib, pkgs }:
let
  mergePlistTool = pkgs.writeShellApplication {
    name = "merge-plist";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      if [ $# -ne 3 ]; then
        echo "usage: merge-plist <target.plist> <keyPath-json> <source.plist>" >&2
        exit 2
      fi
      exec ${pkgs.python3.interpreter} - "$@" << 'EOF'
import sys, json, plistlib

target_path, keypath_json, source_path = sys.argv[1:4]

with open(target_path, 'rb') as f: target = plistlib.load(f)
with open(source_path, 'rb') as f: source = plistlib.load(f)
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

in {
  # Returns a command string for use in scripts
  mergePlists = target: keyPath: source:
    "${mergePlistTool}/bin/merge-plist ${lib.escapeShellArgs [target (builtins.toJSON keyPath) source]}";
  
  # Expose the tool directly
  # inherit mergePlistTool;
}