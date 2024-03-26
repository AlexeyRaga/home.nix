/* Main user-level configuration */
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
    # sometimes it is useful to pin a version of some tool or program.
    # this can be done in "overlays/pinned.nix"
    (import ../overlays/pinned.nix)
  ];

  # Flakes are not standard yet, but widely used, enable them.
  xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
  '';

  imports = [
    # Programs to install
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
    wallpaper.file = ./config/wallpaper/drwho-macos.jpeg;

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
    # fonts
    (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" "FantasqueSansMono" ]; })
  ];

  programs = {
    lazygit.enable = true;
    bat.enable = true;
    navi.enable = true;
    jq.enable = true;
    htop.enable = true;
    bottom.enable = true;
    vim.enable = true;

    broot.enable = true; # better tree

    skim = {
      enable = true;
    };

    eza = {
      enable = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
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

  # services.colima = {
  #   enable = false;

  #   config = {
  #     cpu = 4;
  #     memory = 4;
  #   };
  # };

  tools = {
    aws.enable = true;
    dotnet.enable = true;
    skim.enable = true;

    git = {
      enable = true;
      userName = secrets.github.fullName;
      userEmail = secrets.github.userEmail;
      githubUser = secrets.github.userName;
    };
  };

  ### ZSH (TODO: Maybe Mmve to a module?)
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

    shellAliases = {
      whereis = "function _whereis() { which \"$1\" | xargs realpath; }; _whereis";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./config/p10k;
        file = "p10k-classic.zsh";
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

  targets.darwin.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;

      InitialKeyRepeat = 20;
      KeyRepeat = 2;
    };

    "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

    "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
      MouseButtonMode = "TwoButton";
    };
  };
}
