{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.brews.claude;

in {
  options.brews.claude = {
    enable = mkEnableOption "Enable Claude - AI assistant for MacOS";

    enableGithubMCP = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GitHub MCP server integration";
    };

  };

  systemConfig = mkIf cfg.enable {
    homebrew = {
      casks = [ "claude" ];
    };
  };

  userConfig = mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code
    ];

    home.activation.configureClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
      CLI_CONFIG="$HOME/.claude.json"

      ${if cfg.enableGithubMCP then ''
        # Ensure gh is authenticated (needed for GitHub MCP server)
        if ! ${pkgs.gh}/bin/gh auth status &>/dev/null; then
          echo "Claude: GitHub CLI not authenticated. Please log in:"
          ${pkgs.gh}/bin/gh auth login
        fi

        mkdir -p "$(dirname "$DESKTOP_CONFIG")"
        echo "Claude: Configuring GitHub MCP server"
        GH_TOKEN=$(${pkgs.gh}/bin/gh auth token)
        for settingsFile in "$DESKTOP_CONFIG" "$CLI_CONFIG"; do
          if [ ! -e "$settingsFile" ]; then
            echo '{}' > "$settingsFile"
          fi
          $DRY_RUN_CMD ${pkgs.jq}/bin/jq -S \
            --arg cmd "${pkgs.github-mcp-server}/bin/github-mcp-server" \
            --arg token "$GH_TOKEN" \
            '.mcpServers.github = {command: $cmd, args: ["stdio"], env: {GITHUB_PERSONAL_ACCESS_TOKEN: $token}}' \
            "$settingsFile" > "$settingsFile.tmp" && mv "$settingsFile.tmp" "$settingsFile"
        done
      '' else ''
        for settingsFile in "$DESKTOP_CONFIG" "$CLI_CONFIG"; do
          if [ -e "$settingsFile" ]; then
            echo "Claude: Removing GitHub MCP server from $settingsFile (if present)"
            $DRY_RUN_CMD ${pkgs.jq}/bin/jq -S 'del(.mcpServers.github) | if .mcpServers == {} then del(.mcpServers) else . end' "$settingsFile" > "$settingsFile.tmp" && mv "$settingsFile.tmp" "$settingsFile"
          fi
        done
      ''}
    '';
  };
}