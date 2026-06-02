{ config, lib, pkgs, ... }:

# Comparable to jq / yq, but supports JSON, YAML, TOML, XML and CSV with zero runtime dependencies.

with lib;

let
  cfg = config.tools.dasel;

  # dasel ships no completion files, but the binary can generate them.
  # Override the package to install them via installShellCompletion.
  dasel = pkgs.dasel.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.installShellFiles ];
    postInstall = (old.postInstall or "") + ''
      installShellCompletion --cmd dasel \
        --bash <($out/bin/dasel completion bash) \
        --fish <($out/bin/dasel completion fish) \
        --zsh <($out/bin/dasel completion zsh)
    '';
  });

in {

  options.tools.dasel = {
    enable = mkEnableOption "Enable Dasel";

    enableBashIntegration = mkEnableOption "dasel's bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "dasel's zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "dasel's fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ dasel ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source ${dasel}/share/bash-completion/completions/dasel.bash
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      source ${dasel}/share/zsh/site-functions/_dasel
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${dasel}/share/fish/vendor_completions.d/dasel.fish
    '';
  };
}
