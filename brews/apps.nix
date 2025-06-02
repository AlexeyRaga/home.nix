# Default app configurations
# This file defines which apps are enabled and their global settings.
# All .nix files in this directory are automatically imported by both 
# Darwin and home-manager configurations via importAppModules.
{ config, lib, pkgs, userConfig ? {}, appMode ? "install", appHelpers ? null, ... }:

{
  # Enable greeter app with shared configuration
  brews.greeter = {
    enable = true;
    greeting = "Hello from GREETER!";
  };

  brews.hello = {
    enable = true;
    greeting = "Hello from HELLO!";
  };

  brews.vscode = {
    enable = true;
    extensions = [
        "AdamCaviness.theme-monokai-dark-soda"
        "akamud.vscode-theme-onedark"
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
        "Intility.vscode-backstage"
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
    ];
  };

  # Add other shared app configurations here as needed
  # brews.someOtherApp = {
  #   enable = true;
  #   someOption = "value";
  # };
}
