{ config, lib, pkgs, username, homeDir, ... }:

let
  secrets = import ./secrets;
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.overlays = [
    # (import ./overlays)
  ];

  imports = [
    # everything for work
    ./modules/ep

    ./modules/tools/haskell.nix
    ./modules/tools/dotnet.nix
    ./modules/tools/git.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = homeDir;

    sessionVariables = {
      EDITOR = "vim";
    };

    sessionPath = [
    ];

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    _1password

    # fonts
    (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" "FantasqueSansMono" ]; })
    fira-code

    broot # better tree

    clang
    curl
    curlie
    httpie
    xh

    docker
    duf # better df
    fd # better find
    moreutils
    procs # better ps
    ripgrep # better grep
    tree
    watch
    wget
  ];

  programs.bat.enable = true;
  programs.exa.enable = true;
  programs.jq.enable = true;
  programs.htop.enable = true;
  programs.bottom.enable = true;
  programs.vim.enable = true;

  programs.lsd = {
    enable = true;
    enableAliases = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  tools.aws = {
    enable = true;
    samlProfile = {
      name = "default";
      credentialsPath = "~/Downloads/credentials";
    };
    profiles = secrets.aws.profiles;
  };

  tools.dotnet = {
    enable = true;
    nugetSources = [ ];
  };


  tools.git = {
    enable = true;
    userName = secrets.github.fullName;
    userEmail = secrets.github.userEmail;
    githubUser = secrets.github.userName;
  };

  ### ZSH (TODO: Move to a module)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    # history.extended = true;

    # this is to workaround zsh syntax highlighting slowness on copy/paste
    # https://github.com/zsh-users/zsh-syntax-highlighting/issues/295#issuecomment-214581607
    initExtra = ''
      zstyle ':bracketed-paste-magic' active-widgets '.self-*'

      export DT=''${DT:-''${date}}
    '';

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git-extras"
        "git"
        "gitfast"
        "github"
        "z"
      ];
      #theme = "frozencow";
      theme = "robbyrussell";
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
