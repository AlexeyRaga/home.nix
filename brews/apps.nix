{ config, lib, pkgs, ... }:

{
  brews.apps = {
    casks = [
      "1password"
      "brave-browser" # better chrome
      "cheatsheet"
      "cursor"
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
      "skype"
      "slack"
      "sublime-text"
      "telegram"
      "vlc"
      "warp" # AI-enabled terminal
      "zoom"
      "zed" # code editor
      "mitmproxy"
      "tor-browser" # privacy-focused browser
      "thebrowsercompany-dia" # web browser with AI
    ];
  };

  brews.vscode = {
    enable = true;
    extensions = [
        "amazonwebservices.aws-toolkit-vscode"
        "arrterian.nix-env-selector"
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

  brews.cloudflare-warp = {
    enable = true;
  };

  brews.iterm2 = {
    enable = true;
    theme = "catppuccin-mocha";
  };

  brews.raycast = {
    enable = true;
  };

  brews.magnet = {
    enable = true;

    commands = [
      {
        name = "Top Left Two Thirds";
        id = "D902DA03-47FB-40D5-8015-3499A9EB167E";
        shortcut = [ "Cmd" "CTRL" "." ];
        targetArea = {
          area = {
            segments = [
              {
                id = "5DD6FE34-866B-4127-9219-346433F8AAA1";
                frame = [ [0 0] [8 8] ];
              }
            ];
          };
        };
      }
    ];
  };

  # Add other shared app configurations here as needed
  # brews.someOtherApp = {
  #   enable = true;
  #   someOption = "value";
  # };
}
