{ config, lib, pkgs, ... }:

{
  brews.apps = {
    casks = [
      "1password"
      "brave-browser" # better chrome
      "discord"
      "dropbox"
      "google-chrome"
      "hiddenbar"
      "iina" # modern video player
      "jetbrains-toolbox"
      "intellij-idea"
      "datagrip"
      "licecap" # animated screenshots
      "notion"
      "notion-calendar"
      "postman"
      "hoppscotch" # postman alternative
      "rider"
      "shottr" # screenshot tool
      "slack"
      "sublime-text"
      "telegram"
      "vlc"
      "warp" # AI-enabled terminal
      "zoom"
      "mitmproxy"
      "thebrowsercompany-dia" # web browser with AI
      "zed"
      "dockdoor"
    ];

    brews = [
      "mas" # Required for masApps installations
    ];
  };

  brews.vscode = {
    enable = true;
    extensions = [
        "amazonwebservices.aws-toolkit-vscode"
        "arrterian.nix-env-selector"
        "authzed.spicedb-vscode"
        "bbenoist.Nix"
        "bierner.markdown-mermaid"
        "coolbear.systemd-unit-file"
        "donjayamanne.githistory"
        "eamodio.gitlens"
        "giltho.comby-vscode"
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "GraphQL.vscode-graphql-syntax"
        "GraphQL.vscode-graphql"
        "hashicorp.terraform"
        "haskell.haskell"
        "Ionide.Ionide-fsharp"
        "jnoortheen.nix-ide"
        "JozefChmelar.compare"
        "justusadam.language-haskell"
        "kmoritak.vscode-mermaid-snippets"
        "ms-azuretools.vscode-docker"
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-vscode-remote.remote-containers"
        "ms-vscode.makefile-tools"
        "ms-CopilotStudio.vscode-copilotstudio"
        "PKief.material-icon-theme"
        "redhat.vscode-yaml"
        "streetsidesoftware.avro"
        "vscode-icons-team.vscode-icons"
        "yzhang.markdown-all-in-one"
        "TheNuProjectContributors.vscode-nushell-lang"
        "DrBlury.protobuf-vsc"
        "anthropic.claude-code"
    ];
  };

  brews.rancher = {
    enable = true;
    hostResolver = false;
  };

  brews.iterm2 = {
    enable = true;
    theme = "catppuccin-mocha";
    browserPlugin = {
      enable = true;
      name = "Browser"; # optional, defaults to "Browser"
      shortcut = "B";   # optional, defaults to "Ctrl+Option+B"
    };
  };

  brews.rectangle = {
    enable = true;
    shortcuts = {
      maximize    = "ctrl+option+return";
      restore     = "ctrl+option+delete";
      leftHalf    = "ctrl+option+left";
      rightHalf   = "ctrl+option+right";
      topHalf     = "ctrl+option+up";
      bottomHalf  = "ctrl+option+down";
    };
  };

  brews.boring-notch.enable = true;
  brews.raycast.enable = true;
  
  brews.ice.enable = true;
  brews.meetingbar.enable = true;

  brews.claude.enable = true;
}
