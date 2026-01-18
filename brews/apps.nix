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
      "meetingbar"
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
        "ms-dotnettools.vscodeintellicode-csharp"
        "ms-vscode-remote.remote-containers"
        "ms-vscode.makefile-tools"
        "ms-CopilotStudio.vscode-copilotstudio"
        "PKief.material-icon-theme"
        "redhat.vscode-yaml"
        "streetsidesoftware.avro"
        "vscode-icons-team.vscode-icons"
        "yzhang.markdown-all-in-one"
        "zxh404.vscode-proto3"
        "TheNuProjectContributors.vscode-nushell-lang"
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

  brews.boring-notch.enable = true;
  brews.raycast.enable = true;
  brews.rectangle.enable = true;
  brews.ice.enable = true;

}
