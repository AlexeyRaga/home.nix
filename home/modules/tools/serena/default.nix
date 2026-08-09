{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.tools.serena;

  yamlFormat = pkgs.formats.yaml { };

  # Serena downloads and manages its own language servers at runtime (into
  # ~/.solidlsp/language_servers/static), and those servers need helper
  # runtimes to launch. Wrapping puts them on *Serena's* PATH only.
  #
  # That scoping is deliberate, not incidental: Headroom registers its own
  # Serena MCP entry — `uvx --from git+https://github.com/oraios/serena ...` —
  # but bails out early when `shutil.which("uvx")` comes back empty. Keeping uv
  # out of the login shell means Headroom never registers a competing entry
  # pointing at a runtime git checkout. (Belt and braces: Headroom also refuses
  # to overwrite a `serena` entry missing from its own ledger, so the Nix-owned
  # entry below wins either way.)
  #
  # Only Serena's own entry points are re-exported, deliberately. The package is
  # a venv, so its bin/ also carries every dependency's console script — pip,
  # python, flask, httpx, dotenv — and putting that on PATH wholesale collides
  # with the headroom-ai venv (both ship `dotenv`) and shadows real tools.
  serena = pkgs.runCommand "serena-${cfg.package.version}"
    {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      inherit (cfg.package) meta;
    } ''
      mkdir -p "$out/bin"
      # Globbed rather than a fixed list so that any package providing Serena
      # works here — ours exports serena/serena-agent/serena-hooks, upstream's
      # own flake exports only serena/serena-hooks.
      for prog in ${cfg.package}/bin/serena*; do
        makeWrapper "$prog" "$out/bin/$(basename "$prog")" \
          --prefix PATH : ${makeBinPath cfg.runtimeInputs}
      done
    '';

  mkServerSpec = { context, extraArgs ? [ ] }: {
    command = "${serena}/bin/serena";
    args = [
      "start-mcp-server"
      "--project-from-cwd"
      "--context"
      context
      # Without this Serena opens a browser tab on every single session start.
      # The dashboard backend keeps running and stays reachable at
      # http://localhost:24282/dashboard/ — only the auto-open is suppressed.
      "--open-web-dashboard"
      "False"
    ] ++ extraArgs;
  };

  settingsFile = yamlFormat.generate "serena-settings.yml" cfg.settings;

  serenaHome = "${config.home.homeDirectory}/.serena";

  clientType = types.submodule ({ name, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to register Serena as an MCP server with ${name}.";
      };

      configPath = mkOption {
        type = types.str;
        example = literalExpression ''"''${config.home.homeDirectory}/.claude.json"'';
        description = ''
          Absolute path to the client's JSON config file. Serena is merged in
          under `.mcpServers.serena`; the rest of the file is left alone. The
          file is created as `{}` if it does not exist yet.
        '';
      };

      context = mkOption {
        type = types.str;
        default = "agent";
        description = ''
          Serena context to launch with, which decides the tool set and prompts.
          Serena ships one per client: claude-code, desktop-app, codex, vscode,
          copilot-cli, grok, chatgpt, ide, agent, ... (see `resources/config/contexts`
          in the package).
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "--mode" "planning" ]'';
        description = "Extra arguments appended to `serena start-mcp-server`.";
      };
    };
  });

  registerClient = name: client:
    let
      path = escapeShellArg client.configPath;
      spec = escapeShellArg (builtins.toJSON (mkServerSpec {
        inherit (client) context extraArgs;
      }));
    in
    if client.enable then ''
      if [ ! -e ${path} ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname ${path})"
        $DRY_RUN_CMD echo '{}' > ${path}
      fi
      $VERBOSE_ECHO "Serena: registering MCP server with ${name}"
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq -S --argjson spec ${spec} \
        '.mcpServers.serena = $spec' ${path} > ${path}.tmp \
        && $DRY_RUN_CMD mv ${path}.tmp ${path}
    '' else ''
      if [ -e ${path} ]; then
        $VERBOSE_ECHO "Serena: removing MCP server from ${name} (if present)"
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq -S \
          'del(.mcpServers.serena) | if .mcpServers == {} then del(.mcpServers) else . end' \
          ${path} > ${path}.tmp && $DRY_RUN_CMD mv ${path}.tmp ${path}
      fi
    '';

in {
  options.tools.serena = {
    enable = mkEnableOption "Serena — a coding toolkit exposed to LLM agents over MCP";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The serena-agent package to use.";
    };

    runtimeInputs = mkOption {
      type = types.listOf types.package;
      default = [ pkgs.nodejs pkgs.uv ];
      defaultText = literalExpression "[ pkgs.nodejs pkgs.uv ]";
      example = literalExpression "[ pkgs.nodejs pkgs.uv pkgs.dotnet-sdk pkgs.go ]";
      description = ''
        Packages placed on Serena's PATH (and only Serena's — they are not added
        to {option}`home.packages`).

        Serena fetches its own language servers, so these are the runtimes those
        servers need: node for the many npm-based servers, uv/uvx for the Pyright
        family. Append more for the languages you work in, e.g. `pkgs.dotnet-sdk`
        for C#/F# or `pkgs.go` for gopls.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          log_level = 20;
          tool_timeout = 240;
          excluded_tools = [ "execute_shell_command" ];
        }
      '';
      description = ''
        Settings merged into `~/.serena/serena_config.yml`, taking precedence
        over what is already there.

        The file cannot simply be a store symlink: Serena generates it on first
        run and keeps writing to it afterwards (registering projects, dashboard
        edits). So it is seeded once from the template shipped in the package and
        thereafter these keys are merged over the top on each switch — anything
        Serena wrote itself, `projects` in particular, survives untouched.
      '';
    };

    mcp = {
      clients = mkOption {
        type = types.attrsOf clientType;
        default = { };
        example = literalExpression ''
          {
            claude-desktop.enable = false;
            codebuddy = {
              configPath = "''${config.home.homeDirectory}/.codebuddy/mcp.json";
              context = "codebuddy";
            };
          }
        '';
        description = ''
          MCP clients to register Serena with. `claude-code` and `claude-desktop`
          are pre-declared and enabled; add an entry for any other client that
          keeps its servers under `mcpServers` in a JSON file.

          For clients that are not JSON — Codex's TOML config, say — use
          {option}`tools.serena.mcp.mkServerSpec` and write the entry yourself.
        '';
      };

      mkServerSpec = mkOption {
        type = types.functionTo (types.attrsOf types.anything);
        readOnly = true;
        default = mkServerSpec;
        defaultText = literalExpression "<function>";
        description = ''
          Escape hatch for clients this module does not write itself.
          `mkServerSpec { context = "codex"; }` returns the MCP server entry
          — `{ command, args }`, pointing at the wrapped Nix store binary —
          ready to splice into any config format you like.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ serena ];

    # Defined here rather than as option defaults so that adding a client, or
    # overriding one field of a built-in, merges instead of replacing the lot.
    tools.serena.settings = {
      web_dashboard_open_on_launch = mkDefault false;
      gui_log_window = mkDefault false;
    };

    tools.serena.mcp.clients = {
      claude-code = {
        configPath = mkDefault "${config.home.homeDirectory}/.claude.json";
        context = mkDefault "claude-code";
      };
      claude-desktop = {
        configPath = mkDefault
          "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
        context = mkDefault "desktop-app";
      };
    };

    home.activation.serenaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SERENA_CONFIG=${escapeShellArg "${serenaHome}/serena_config.yml"}
      $DRY_RUN_CMD mkdir -p ${escapeShellArg serenaHome}

      # Seed via Serena's own `init` rather than an empty file — it raises
      # SerenaConfigError on a config with no `projects` key. Using the
      # supported entry point (instead of copying the template out of
      # site-packages) keeps this independent of how Serena was packaged.
      if [ ! -e "$SERENA_CONFIG" ]; then
        $VERBOSE_ECHO "Serena: creating serena_config.yml via 'serena init'"
        $DRY_RUN_CMD env SERENA_HOME=${escapeShellArg serenaHome} \
          ${serena}/bin/serena init > /dev/null
      fi
      ${optionalString (cfg.settings != { }) ''
        $VERBOSE_ECHO "Serena: merging declarative settings into serena_config.yml"
        $DRY_RUN_CMD ${pkgs.yq-go}/bin/yq eval-all \
          'select(fileIndex == 0) * select(fileIndex == 1)' \
          "$SERENA_CONFIG" ${settingsFile} > "$SERENA_CONFIG.tmp" \
          && $DRY_RUN_CMD mv "$SERENA_CONFIG.tmp" "$SERENA_CONFIG"
      ''}
    '';

    home.activation.serenaMcp = lib.hm.dag.entryAfter [ "writeBoundary" ]
      (concatStringsSep "\n" (mapAttrsToList registerClient cfg.mcp.clients));
  };
}
