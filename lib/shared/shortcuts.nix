{ lib, pkgs }:

let
  inherit (lib) strings lists;

  # Common key codes for macOS keyboard shortcuts
  # Based on Carbon/IOKit keycodes
  # Source: /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Headers/Events.h
  keyCodes = {
    # Letters
    "A" = 0; "a" = 0;
    "S" = 1; "s" = 1;
    "D" = 2; "d" = 2;
    "F" = 3; "f" = 3;
    "H" = 4; "h" = 4;
    "G" = 5; "g" = 5;
    "Z" = 6; "z" = 6;
    "X" = 7; "x" = 7;
    "C" = 8; "c" = 8;
    "V" = 9; "v" = 9;
    "B" = 11; "b" = 11;
    "Q" = 12; "q" = 12;
    "W" = 13; "w" = 13;
    "E" = 14; "e" = 14;
    "R" = 15; "r" = 15;
    "Y" = 16; "y" = 16;
    "T" = 17; "t" = 17;
    "L" = 37; "l" = 37;
    "J" = 38; "j" = 38;
    "K" = 40; "k" = 40;
    "N" = 45; "n" = 45;
    "M" = 46; "m" = 46;
    "O" = 31; "o" = 31;
    "U" = 32; "u" = 32;
    "I" = 34; "i" = 34;
    "P" = 35; "p" = 35;

    # Numbers
    "1" = 18; "2" = 19; "3" = 20; "4" = 21; "5" = 23;
    "6" = 22; "7" = 26; "8" = 28; "9" = 25; "0" = 29;

    # Special characters
    "=" = 24;
    "-" = 27;
    "]" = 30;
    "[" = 33;
    "'" = 39;
    ";" = 41;
    "\\" = 42;
    "," = 43;
    "/" = 44;
    "." = 47;
    "`" = 50;

    # Special keys
    "return" = 36;
    "enter" = 36;
    "tab" = 48;
    "space" = 49;
    "delete" = 51;
    "backspace" = 51;
    "escape" = 53;
    "esc" = 53;

    # Arrow keys
    "left" = 123;
    "right" = 124;
    "down" = 125;
    "up" = 126;

    # Function keys
    "f1" = 122;
    "f2" = 120;
    "f3" = 99;
    "f4" = 118;
    "f5" = 96;
    "f6" = 97;
    "f7" = 98;
    "f8" = 100;
    "f9" = 101;
    "f10" = 109;
    "f11" = 103;
    "f12" = 111;
    "f13" = 105;
    "f14" = 107;
    "f15" = 113;
    "f16" = 106;
    "f17" = 64;
    "f18" = 79;
    "f19" = 80;
    "f20" = 90;

    # Keypad
    "keypad." = 65;
    "keypad*" = 67;
    "keypad+" = 69;
    "keypadClear" = 71;
    "keypad/" = 75;
    "keypadEnter" = 76;
    "keypad-" = 78;
    "keypad=" = 81;
    "keypad0" = 82;
    "keypad1" = 83;
    "keypad2" = 84;
    "keypad3" = 85;
    "keypad4" = 86;
    "keypad5" = 87;
    "keypad6" = 88;
    "keypad7" = 89;
    "keypad8" = 91;
    "keypad9" = 92;

    # Additional navigation
    "home" = 115;
    "end" = 119;
    "pageup" = 116;
    "pagedown" = 121;
    "del" = 117;  # Forward delete
  };

  # Modifier masks for modern macOS (IOKit/Cocoa)
  # Used in system preferences, Rectangle, and most modern apps
  # Source: /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Headers/hidsystem/IOLLEvent.h
  # These are bit flags that can be combined using addition (or bitwise OR)
  modifierMasks = {
    "shift" = 131072;    # 0x020000
    "control" = 262144;  # 0x040000
    "option" = 524288;   # 0x080000
    "command" = 1048576; # 0x100000
  };

  # Carbon modifier flags (legacy apps like Magnet)
  # These are DIFFERENT from the modern IOKit values above!
  carbonModifiers = {
    "SHIFT" = 512;
    "shift" = 512;
    "CONTROL" = 4096;
    "CTRL" = 4096;
    "control" = 4096;
    "ctrl" = 4096;
    "OPTION" = 2048;
    "OPT" = 2048;
    "ALT" = 2048;
    "option" = 2048;
    "opt" = 2048;
    "alt" = 2048;
    "COMMAND" = 256;
    "CMD" = 256;
    "command" = 256;
    "cmd" = 256;
  };

  # Normalize modifier names to a canonical form for consistent ordering
  normalizeModifier = mod:
    let lower = strings.toLower mod;
    in if lower == "ctrl" then "control"
    else if lower == "cmd" then "command"
    else if lower == "opt" || lower == "alt" then "option"
    else lower;

  # Sort modifiers in canonical order: shift, control, option, command
  sortModifiers = modifiers:
    let
      normalized = map normalizeModifier modifiers;
      order = { shift = 0; control = 1; option = 2; command = 3; };
      getOrder = mod: order.${mod} or 999;
    in
    lists.sort (a: b: getOrder a < getOrder b) normalized;

in
rec {
  # Export the lookup tables
  inherit keyCodes modifierMasks carbonModifiers;

  # Helper to convert human-readable key combinations to modern macOS format (IOKit/Cocoa)
  # Used for system preferences, Rectangle, and most modern apps
  # Modifiers are bit flags that are combined using addition
  # 
  # Example:
  #   mkShortcut { key = "n"; modifiers = ["ctrl" "option"]; }
  #   => { keyCode = 45; modifierFlags = 786432; }
  mkShortcut = { key, modifiers ? [] }:
    let
      keyCode = keyCodes.${key} or (throw "Unknown key: ${key}");
      modFlags = builtins.foldl' (acc: mod:
        let normalized = normalizeModifier mod;
        in acc + (modifierMasks.${normalized} or (throw "Unknown modifier: ${mod}"))
      ) 0 modifiers;
    in
    {
      inherit keyCode;
      modifierFlags = modFlags;
    };

  # Helper for legacy Carbon-based shortcuts (Magnet, etc.)
  # Carbon uses different modifier values than modern macOS!
  # 
  # Example:
  #   mkCarbonShortcut { key = "N"; modifiers = ["CTRL" "OPTION"]; }
  #   => { carbonKeyCode = 45; carbonModifiers = 6144; }
  mkCarbonShortcut = { key, modifiers ? [] }:
    let
      keyCode = keyCodes.${key} or (throw "Unknown key: ${key}");
      calculateModifiers = mods:
        builtins.foldl' (acc: mod: 
          acc + (carbonModifiers.${mod} or (throw "Unknown Carbon modifier: ${mod}"))
        ) 0 mods;
    in
    {
      carbonKeyCode = keyCode;
      carbonModifiers = calculateModifiers modifiers;
    };

  # Parse a shortcut string like "ctrl+option+n" into components
  # Returns: { key = "n"; modifiers = ["ctrl" "option"]; }
  parseShortcutString = shortcutStr:
    let
      parts = strings.splitString "+" shortcutStr;
      key = lists.last parts;
      modifiers = lists.init parts;
    in
    { inherit key modifiers; };

  # Convert a shortcut string directly to modern macOS format
  # Example: mkShortcutFromString "ctrl+option+n"
  mkShortcutFromString = shortcutStr:
    let parsed = parseShortcutString shortcutStr;
    in mkShortcut parsed;

  # Convert a shortcut string directly to Carbon format
  mkCarbonShortcutFromString = shortcutStr:
    let parsed = parseShortcutString shortcutStr;
    in mkCarbonShortcut parsed;

  # Flexible shortcut converter - accepts multiple input formats
  # Useful for module options that want to accept user-friendly input
  # 
  # Accepts:
  #   - String: "ctrl+option+n"
  #   - Attrset with key/modifiers: { key = "n"; modifiers = ["ctrl" "option"]; }
  #   - Already formatted: { keyCode = 45; modifierFlags = 786432; }
  # 
  # Example:
  #   convertShortcut "ctrl+option+n"
  #   convertShortcut { key = "n"; modifiers = ["ctrl" "option"]; }
  #   => Both return: { keyCode = 45; modifierFlags = 786432; }
  convertShortcut = shortcut:
    if builtins.isString shortcut then
      mkShortcutFromString shortcut
    else if builtins.isAttrs shortcut && shortcut ? keyCode && shortcut ? modifierFlags then
      shortcut
    else if builtins.isAttrs shortcut && shortcut ? key then
      mkShortcut shortcut
    else
      throw "Invalid shortcut format. Expected string, { key, modifiers }, or { keyCode, modifierFlags }";

  # Helper to calculate combined modifier value from a list of modifier names
  # For modern macOS format (combines bit flags using addition)
  combineModifiers = modifiers:
    builtins.foldl' (acc: mod:
      let normalized = normalizeModifier mod;
      in acc + (modifierMasks.${normalized} or (throw "Unknown modifier: ${mod}"))
    ) 0 modifiers;

  # Helper to calculate Carbon modifier value from a list of modifier names
  combineCarbonModifiers = modifiers:
    builtins.foldl' (acc: mod:
      acc + (carbonModifiers.${mod} or (throw "Unknown Carbon modifier: ${mod}"))
    ) 0 modifiers;
}