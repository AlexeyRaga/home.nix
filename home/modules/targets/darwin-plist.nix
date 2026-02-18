{ config, lib, pkgs, user, ... }:

with lib;

let
  cfg = config.targets.darwin.plists;

  # Convert domain name to plist path
  # If it starts with ~/ or /, use as-is; otherwise assume it's a domain
  domainToPlistPath = domain:
    if hasPrefix "~/" domain || hasPrefix "/" domain
    then domain
    else "${user.home or "~"}/Library/Preferences/${domain}.plist";

  # Convert bundle ID to sandboxed container plist path
  containerToPlistPath = bundleId:
    "${user.home or "~"}/Library/Containers/${bundleId}/Data/Library/Preferences/${bundleId}.plist";

  # Generate activation commands for a single plist file
  generatePlistCommands = plistPath: value:
    let
      escapedPath = lib.escapeShellArg plistPath;
    in
    ''
      # Merge plist configuration for ${plistPath}
      run ${lib.plists.mergeValue escapedPath [] value}
    '';

  # Generate commands for regular plists
  regularCommands = lib.mapAttrsToList
    (domain: value:
      if domain == "containers"
      then "" # Skip containers attribute, handled separately
      else generatePlistCommands (domainToPlistPath domain) value)
    cfg;

  # Generate commands for container plists
  containerCommands = lib.mapAttrsToList
    (bundleId: value: generatePlistCommands (containerToPlistPath bundleId) value)
    (cfg.containers or {});

  # Combine all commands
  allCommands = lib.concatStringsSep "\n\n"
    (builtins.filter (cmd: cmd != "") (regularCommands ++ containerCommands));

in
{
  options.targets.darwin.plists = mkOption {
    type = types.attrsOf types.anything;
    default = {};
    example = literalExpression ''
      {
        # Domain-based (auto-resolves to ~/Library/Preferences/domain.plist)
        "com.googlecode.iterm2" = {
          "Custom Color Presets" = {
            "MyTheme" = {
              "Ansi 0 Color" = { Blue = 0; Green = 0; Red = 0; };
            };
          };
        };

        # Sandboxed container apps
        containers = {
          "theboringteam.boringnotch" = {
            enableSneakPeek = false;
            showMirror = false;
          };
        };

        # Explicit file path
        "~/custom/config.plist" = {
          someKey = "value";
          nested = {
            setting = 42;
          };
        };
      }
    '';
    description = ''
      Declarative macOS plist configuration using deep merge.

      Keys can be either:
      - Domain names (e.g., "com.example.app") which resolve to ~/Library/Preferences/domain.plist
      - Explicit file paths (starting with ~/ or /)
      - "containers" attribute for sandboxed apps (see below)

      For sandboxed container apps, use the "containers" attribute:
        containers."bundle-id" = { settings };
      This resolves to: ~/Library/Containers/<bundle-id>/Data/Library/Preferences/<bundle-id>.plist

      Values are recursively deep merged with existing plist content, preserving
      settings not specified in the configuration.

      This is more flexible than targets.darwin.defaults as it supports:
      - Nested dictionaries with deep merging
      - Working with any plist file location (including containers)
      - Preserving existing settings while updating specific values
    '';
  };

  config = mkIf (cfg != {}) {
    home.activation.setDarwinPlists = lib.hm.dag.entryAfter [ "writeBoundary" "setDarwinDefaults" ] ''
      ${allCommands}
    '';
  };
}
