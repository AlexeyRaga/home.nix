{ config, lib, pkgs, ... }:

{
  darwin.apps = {
    raycast.enable = true;
    iterm2.enable = true;
    rancher.enable = true;
    cloudflare-warp.enable = true;

    vscode = {
      enable = true;
      extensions = [
        "AdamCaviness.theme-monokai-dark-soda"
        "GitHub.copilot"
        "GraphQL.vscode-graphql"
        "GraphQL.vscode-graphql-syntax"
        "Intility.vscode-backstage"
        "Ionide.Ionide-fsharp"
        "PKief.material-icon-theme"
        "akamud.vscode-theme-onedark"
        "amazonwebservices.aws-toolkit-vscode"
        "arrterian.nix-env-selector"
        "bbenoist.Nix"
        "bierner.markdown-mermaid"
        "coolbear.systemd-unit-file"
        "donjayamanne.githistory"
        "eamodio.gitlens"
        "giltho.comby-vscode"
        "hashicorp.terraform"
        "haskell.haskell"
        "jnoortheen.nix-ide"
        "justusadam.language-haskell"
        "kmoritak.vscode-mermaid-snippets"
        "ms-azuretools.vscode-docker"
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-dotnettools.vscodeintellicode-csharp"
        "ms-vscode-remote.remote-containers"
        "ms-vscode.makefile-tools"
        "redhat.vscode-yaml"
        "streetsidesoftware.avro"
        "vscode-icons-team.vscode-icons"
        "yzhang.markdown-all-in-one"
        "zxh404.vscode-proto3"
      ];
    };
  };

  homebrew = {
    enable = true;

    casks = [
      "1password"
      "brave-browser" # better chrome
      "cheatsheet"
      "cursor"
      "discord"
      "dropbox"
      "google-chrome"
      "jetbrains-toolbox"
      "licecap" # animated screenshots
      "notion"
      "notion-calendar"
      "postman"
      "rider"
      "skype"
      "slack"
      "sublime-text"
      "telegram"
      "vlc"
      "zoom"
    ];

    brews = [

    ];

    masApps = {
      Magnet = 441258766;
    };

    global.brewfile = true;
    onActivation.cleanup = "zap";

    taps = [
    ];
  };
}
