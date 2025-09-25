{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.magnet;

  carbonKeyCodes = {
    "A" = 0; "S" = 1; "D" = 2; "F" = 3; "H" = 4; "G" = 5; "Z" = 6; "X" = 7; "C" = 8;
    "V" = 9; "B" = 11; "Q" = 12; "W" = 13; "E" = 14; "R" = 15; "Y" = 16; "T" = 17;
    "1" = 18; "2" = 19; "3" = 20; "4" = 21; "6" = 22; "5" = 23; "=" = 24; "9" = 25;
    "7" = 26; "-" = 27; "8" = 28; "0" = 29; "]" = 30; "O" = 31; "U" = 32; "[" = 33;
    "I" = 34; "P" = 35; 
    "ENTER" = 36; "ENT" = 36; "RET" = 36; "CR" = 36;
    "L" = 37; "J" = 38; "'" = 39; "K" = 40; ";" = 41; "\\" = 42;
    "," = 43; "/" = 44; "N" = 45; "M" = 46; "." = 47; "`" = 50; "BS" = 51; "BACK" = 51; "BACKSPACE" = 51;
    "ESC" = 53;
    "HOME" = 115; "END" = 119; "DEL" = 117; "DELETE" = 117;
    "PGUP" = 116; "PGDN" = 121; "PGDOWN" = 121;
    "UP" = 126; "DOWN" = 125; "DN" = 125;
    "LEFT" = 123; "RIGHT" = 124;
    "NUM_0" = 82; "NUM_1" = 83; "NUM_2" = 84; "NUM_3" = 85; "NUM_4" = 86; "NUM_5" = 87;
    "NUM_6" = 88; "NUM_7" = 89; "NUM_8" = 91; "NUM_9" = 92;
    "NUM_*" = 67; "NUM_+" = 69; "NUM_/" = 75; "NUM_-" = 78; 
    "NUM_ENTER" = 52; "NUM_ENT" = 52; "NUM_RET" = 52; "NUM_CR" = 52;
  };

  # Define modifier flags for Carbon
  carbonModifiers = {
    "SHIFT" = 512; 
    "CONTROL" = 4096; "CRTL" = 4096; 
    "OPTION" = 2048; "OPT" = 2048; "ALT" = 2048;
    "COMMAND" = 256; "CMD" = 256;
  };

  calculateModifiers = modifiers:
    builtins.foldl' (acc: mod: acc + (builtins.getAttr (lib.strings.toUpper mod) carbonModifiers)) 0 modifiers;

  calculateCarbonShortcut = shortcut:
    let
      isModifier = x: builtins.hasAttr (lib.strings.toUpper x) carbonModifiers;
      isKey = x: builtins.hasAttr (lib.strings.toUpper x) carbonKeyCodes;

      # Partition shortcut into modifiers and key
      modifiers = builtins.filter isModifier shortcut;
      key = builtins.filter isKey shortcut;

    in if (builtins.length key) == 1 then {
      carbonKeyCode = builtins.getAttr (lib.strings.toUpper (builtins.elemAt key 0)) carbonKeyCodes;
      carbonModifiers = calculateModifiers modifiers;
    } else
      throw "Shortcut must contain exactly one key.";

  convertShortcut = obj:
    let
      keyboardShortcut = if builtins.hasAttr "shortcut" obj then
        {
          enabled = true;
          available = true;
          shortcut = calculateCarbonShortcut obj.shortcut;
        }
      else
        null;
    in obj // { keyboardShortcut = keyboardShortcut; } // { shortcut = null; };

  guid = mkOptionType {
    check = value: builtins.match "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$" value != null;
    name = "GUID";
    description = "A string in GUID format, e.g., 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'.";
  };

  enabledAvailable = lib.types.submodule {
    options = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the feature is enabled.";
      };
      available = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the feature is available.";
      };
    };
  };

  segment = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = guid;
        description = "Unique identifier for the segment.";
      };
      frame = lib.mkOption {
        type = lib.types.listOf (lib.types.listOf lib.types.int);
        description = "The frame defining the segment as a list of two coordinate pairs.";
        example = [ [ 0 0 ] [ 12 6 ] ];
      };
    };
  };

  area = lib.types.submodule {
    options = {
      segments = lib.mkOption {
        type = lib.types.listOf segment;
        default = [];
        description = "List of segments defining the area.";
      };
    };
  };

  targetArea = lib.types.submodule {
    options = {
      available = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the target area is available.";
      };
      area = lib.mkOption {
        type = area;
        description = "The area of the target.";
      };
    };
  };

  command = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = guid;
        description = "Unique identifier for the command.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the command.";
      };
      visibleInMenuBar = lib.mkOption {
        type = enabledAvailable;
        default = { enabled = true; available = true; };
        description = "Whether the command is visible in the menu bar.";
      };
      activationArea = lib.mkOption {
        type = enabledAvailable;
        default = { enabled = false; available = true; };
        description = "The activation area for the command.";
      };
      visibleInGreenButtonMenu = lib.mkOption {
        type = enabledAvailable;
        default = { enabled = true; available = true; };
        description = "Whether the command is visible in the green button menu.";
      };
      axis = lib.mkOption {
        type = lib.types.enum [ "horizontal" "vertical" ];
        default = "horizontal";
        description = "Axis of the command.";
      };
      targetArea = lib.mkOption {
        type = targetArea;
        description = "The target area for the command.";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "custom";
        description = "Category of the command.";
      };
      shortcut = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Shortcut for the command.";
        example = [ "Cmd" "Ctrl" "A" ];
      };
    };
  };

in 
{
  options.brews.magnet = {
    enable = mkEnableOption "Enable Magnet - window manager for MacOS";

    commands = mkOption {
      type = lib.types.listOf command;
      default = [];
      description = "List of commands for Magnet.";
    };
  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      masApps = {
        Magnet = 441258766;
      };
    };
  };

  userConfig = mkIf cfg.enable {
    # Home-manager activation script for magnet configuration
    home.activation.configureMagnet = lib.hm.dag.entryAfter [ "writeBoundary" ] 
      (let jsonCommands = builtins.toJSON (map convertShortcut cfg.commands);
    in ''
      /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Magnet.app\", hidden:false}"
    
    #   CONFIG_PATH="$HOME/Library/Preferences/com.crowdcafe.windowmagnet.plist"
    #   DEBUG_FILE="$HOME/.cache/magnet-debug.json"
      
    #   # Create cache directory if it doesn't exist
    #   mkdir -p "$HOME/.cache"
      
    #   hconfig=$(/usr/libexec/PlistBuddy -c "Print horizontalCommands" $CONFIG_PATH)
    #   commands='${jsonCommands}'

    #   jq -n --argjson data1 "$hconfig" --argjson data2 "$commands" '
    #     $data1 as $orig |
    #     $data2 as $cmds |

    #     ($orig | map(select(.id?)) | map({key: .id, value: .}) | from_entries) as $orig_by_id |
    #     ($cmds | map(select(.id?)) | map({key: .id, value: .}) | from_entries) as $commands_by_id |
        
    #     # Merge orig.json, replacing entries with the same id with commands.json
    #     ($orig | map(if .id? and $commands_by_id[.id] then $commands_by_id[.id] else . end)) +
        
    #     # Add new entries from commands.json with id not in orig.json
    #     ($cmds | map(select(.id? and (.id as $id | $orig_by_id[$id] | not)))) +

    #     # Add all entries without ids from commands.json
    #     ($cmds | map(select(.id? | not)))
    # ' > "$DEBUG_FILE"
    
    # echo "Magnet configuration written to: $DEBUG_FILE"

    /usr/bin/osascript -e 'tell application "Magnet" to launch'
    '');
  };
}
