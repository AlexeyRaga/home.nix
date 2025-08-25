{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.iterm2;

  shell_integration = pkgs.fetchFromGitHub {
    name = "iterm2-shell-integration";
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "4999d188aba9e470fa921367288ab6d5074b5324";
    sha256 = "sha256-HXmZty8emMoUtyuJpLLY+IfHBIJjG9wUJNGv0a3hJBc=";
  };
  utilities = builtins.attrNames (builtins.readDir "${shell_integration}/utilities");
  aliases = lib.concatMapStringsSep ";" (x: "alias ${x}='${shell_integration}/utilities/${x}'") utilities;
in
{
  options.brews.iterm2 = {
    enable = mkEnableOption "Enable iTerm2 - the best terminal for MacOS";

    font = mkOption {
      type = types.str;
      default = "FiraCodeNFM-Reg 12";
    };

    columns = mkOption {
      type = types.ints.positive;
      default = 150;
      description = "Terminal window size (horizontal)";
    };

    rows = mkOption {
      type = types.ints.positive;
      default = 40;
      description = "Terminal window size (vertical)";
    };
  };

  systemConfig = mkIf cfg.enable {
      # Install mode: Darwin/homebrew configuration
    homebrew = {
      casks = [ "iterm2" ];
    };

    # targets.darwin.plists = {
    #   "Library/Preferences/com.googlecode.iterm2.plist" = {
    #     "New Bookmarks:0:Normal Font" = cfg.font;
    #     "New Bookmarks:0:Columns" = toString cfg.columns;
    #     "New Bookmarks:0:Rows" = toString cfg.rows;
    #     "New Bookmarks:0:Silence Bell" = "1";
    #     "New Bookmarks:0:Custom Directory" = "Recycle";
		# 		"New Bookmarks:0:Guid" = "nightfox";
    #   };
    # };

    # Initialise Shell Integration
    programs.bash.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
      ${aliases}
    '';
    programs.fish.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';
  };

      # Configure mode: Home-manager configuration  
  userConfig = mkIf cfg.enable {
    # Shell integration for home-manager
    programs.bash.initExtra = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
      ${aliases}
    '';
    programs.fish.shellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.initContent = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';

		home.activation.configureIterm = 
			let 
				plist = "~/Library/Preferences/com.googlecode.iterm2.plist"; 
			in lib.hm.dag.entryAfter [ "linkGeneration" ] ''
			/usr/libexec/PlistBuddy -c "Add :'Custom Color Presets':'Nightfox' dict" ${plist} >/dev/null 2>&1 || true
			/usr/libexec/PlistBuddy -c "Merge '${config.xdg.configFile."iterm2/nightfox.itermcolors".source}' :'Custom Color Presets':'Nightfox'" ${plist}

			/usr/libexec/PlistBuddy \
				-c "Set :'New Bookmarks':0:'Normal Font' '${cfg.font}'" \
				-c "Set :'New Bookmarks':0:'Columns' ${toString cfg.columns}" \
				-c "Set :'New Bookmarks':0:'Rows' ${toString cfg.rows}" \
				-c "Set :'New Bookmarks':0:'Silence Bell' 1" \
				-c "Set :'New Bookmarks':0:'Custom Directory' Recycle" \
				-c "Set :'New Bookmarks':0:'Guid' nightfox" \
				${plist}
			'';

    xdg.configFile."iterm2/nightfox.itermcolors".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>Ansi 0 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.26666668057441711</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.23137255012989044</real>
    		<key>Red Component</key>
    		<real>0.22352941334247589</real>
    	</dict>
    	<key>Ansi 1 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.42745098471641541</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.30980393290519714</real>
    		<key>Red Component</key>
    		<real>0.78823530673980713</real>
    	</dict>
    	<key>Ansi 10 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.54509806632995605</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.80392158031463623</real>
    		<key>Red Component</key>
    		<real>0.34509804844856262</real>
    	</dict>
    	<key>Ansi 11 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.49411764740943909</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.89019608497619629</real>
    		<key>Red Component</key>
    		<real>1</real>
    	</dict>
    	<key>Ansi 12 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.89411765336990356</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.80784314870834351</real>
    		<key>Red Component</key>
    		<real>0.51764708757400513</real>
    	</dict>
    	<key>Ansi 13 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.89019608497619629</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.63137257099151611</real>
    		<key>Red Component</key>
    		<real>0.72156864404678345</real>
    	</dict>
    	<key>Ansi 14 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>1</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.94117647409439087</real>
    		<key>Red Component</key>
    		<real>0.3490196168422699</real>
    	</dict>
    	<key>Ansi 15 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.94901961088180542</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.94901961088180542</real>
    		<key>Red Component</key>
    		<real>0.94901961088180542</real>
    	</dict>
    	<key>Ansi 2 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.60392159223556519</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.69803923368453979</real>
    		<key>Red Component</key>
    		<real>0.5058823823928833</real>
    	</dict>
    	<key>Ansi 3 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.45490196347236633</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.75294119119644165</real>
    		<key>Red Component</key>
    		<real>0.85882353782653809</real>
    	</dict>
    	<key>Ansi 4 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.83921569585800171</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.61176472902297974</real>
    		<key>Red Component</key>
    		<real>0.44313725829124451</real>
    	</dict>
    	<key>Ansi 5 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.83921569585800171</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.47450980544090271</real>
    		<key>Red Component</key>
    		<real>0.61568629741668701</real>
    	</dict>
    	<key>Ansi 6 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.81176471710205078</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.80392158031463623</real>
    		<key>Red Component</key>
    		<real>0.38823530077934265</real>
    	</dict>
    	<key>Ansi 7 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.87843137979507446</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.87450981140136719</real>
    		<key>Red Component</key>
    		<real>0.87450981140136719</real>
    	</dict>
    	<key>Ansi 8 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.44705882668495178</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.31372550129890442</real>
    		<key>Red Component</key>
    		<real>0.27843138575553894</real>
    	</dict>
    	<key>Ansi 9 Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.41960784792900085</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.3803921639919281</real>
    		<key>Red Component</key>
    		<real>0.83921569585800171</real>
    	</dict>
    	<key>Background Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.18823529779911041</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.13725490868091583</real>
    		<key>Red Component</key>
    		<real>0.098039217293262482</real>
    	</dict>
    	<key>Badge Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>0.5</real>
    		<key>Blue Component</key>
    		<real>0.0</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.14910027384757996</real>
    		<key>Red Component</key>
    		<real>1</real>
    	</dict>
    	<key>Bold Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.99999994039535522</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.99999994039535522</real>
    		<key>Red Component</key>
    		<real>1</real>
    	</dict>
    	<key>Cursor Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.78104287385940552</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.78104287385940552</real>
    		<key>Red Component</key>
    		<real>0.78104299306869507</real>
    	</dict>
    	<key>Cursor Guide Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>0.25</real>
    		<key>Blue Component</key>
    		<real>1</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.92681378126144409</real>
    		<key>Red Component</key>
    		<real>0.70214027166366577</real>
    	</dict>
    	<key>Cursor Text Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.99999994039535522</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.99999994039535522</real>
    		<key>Red Component</key>
    		<real>1</real>
    	</dict>
    	<key>Foreground Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.81176471710205078</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.80784314870834351</real>
    		<key>Red Component</key>
    		<real>0.80392158031463623</real>
    	</dict>
    	<key>Link Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.73422712087631226</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.35915297269821167</real>
    		<key>Red Component</key>
    		<real>0.0</real>
    	</dict>
    	<key>Selected Text Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>0.0</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.0</real>
    		<key>Red Component</key>
    		<real>0.0</real>
    	</dict>
    	<key>Selection Color</key>
    	<dict>
    		<key>Alpha Component</key>
    		<real>1</real>
    		<key>Blue Component</key>
    		<real>1</real>
    		<key>Color Space</key>
    		<string>sRGB</string>
    		<key>Green Component</key>
    		<real>0.86968445777893066</real>
    		<key>Red Component</key>
    		<real>0.75813823938369751</real>
    	</dict>
    </dict>
    </plist>
  '';
  };
}
