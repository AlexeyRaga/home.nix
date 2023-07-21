{ config, lib, pkgs, ... }:

{
  darwin.apps = {
    raycast.enable = true;
    iterm2.enable = true;

    vscode = {
      enable = true;
      extensions = [
        "AdamCaviness.theme-monokai-dark-soda"
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
        "joaompinto.vscode-graphviz"
        "justusadam.language-haskell"
        "kmoritak.vscode-mermaid-snippets"
        "ms-azuretools.vscode-docker"
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-dotnettools.vscodeintellicode-csharp"
        "ms-vscode-remote.remote-containers"
        "ms-vscode.makefile-tools"
        "ms-vsliveshare.vsliveshare-pack"
        "redhat.vscode-yaml"
        "streetsidesoftware.avro"
        "vscode-icons-team.vscode-icons"
        "zxh404.vscode-proto3"
      ];
    };
  };

  homebrew = {
    enable = true;

    global.brewfile = true;
    onActivation.cleanup = "zap";

    taps = [
      "homebrew/cask"
      "homebrew/core"
    ];

    casks = [
      "1password"
      "brave-browser" # better chrome
      "cheatsheet"
      "cloudflare-warp"
      "discord"
      "dropbox"
      "google-chrome"
      "jetbrains-toolbox"
      "licecap" # animated screenshots
      "openvpn-connect"
      "postman"
      "rancher"
      "rider"
      "skype"
      "slack"
      "sublime-text"
      "telegram"
      "vlc"
      "warp" # new terminal
      "zoom"
    ];

    brews = [

    ];

    masApps = {
      Magnet = 441258766;
    };
  };
}
