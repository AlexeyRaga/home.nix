{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets;
  modules = import ../lib/modules.nix {inherit lib;};
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../overlays/pinned.nix)
  ];

  xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
  '';

  imports = [
    ./packages.nix

    # everything for work
    ./work
  ] ++ (modules.importAllModules ./modules);

  # secureEnv.onePassword = {
  #   enable = true;
  #   sessionVariables = {
  #     GITHUB_TOKEN = {
  #       vault = "Private";
  #       item = "Github Token";
  #       field = "password";
  #     };
  #   };
  # };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = config.user.name;
    homeDirectory = config.user.home;

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
  ];

  programs = {
    lazygit.enable = true;
    bat.enable = true;
    exa.enable = true;
    jq.enable = true;
    htop.enable = true;
    bottom.enable = true;
    vim.enable = true;

    lsd = {
      enable = true;
      enableAliases = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    lf.enable = true;
  };

  services.colima = {
    enable = false;

    config = {
      cpu = 4;
      memory = 4;
    };
  };


  programs.ssh = {
    enable = true;
    matchBlocks = {
      "remarkable" = {
        user = "root";
        hostname = "10.11.99.1";
      };
    };
  };

  tools.aws = {
    enable = true;
    credentials = secrets.aws.credentials;
  };

  tools.dotnet = {
    enable = true;
  };

  tools.spacevim = {
    enable = false;
  };

  tools.git = {
    enable = true;
    userName = secrets.github.fullName;
    userEmail = secrets.github.userEmail;
    githubUser = secrets.github.userName;
  };

  ### ZSH (TODO: Move to a module)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    # history.extended = true;

    # this is to workaround zsh syntax highlighting slowness on copy/paste
    # https://github.com/zsh-users/zsh-syntax-highlighting/issues/295#issuecomment-214581607
    initExtra = ''
      zstyle ':bracketed-paste-magic' active-widgets '.self-*'
    '';

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./config/p10k;
        file = "p10k.zsh";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "dirhistory"
        "git-extras"
        "git"
        "gitfast"
        "github"
        "z"
      ];
      # theme = "robbyrussell";
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
