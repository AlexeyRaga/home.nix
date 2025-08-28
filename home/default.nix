/* Main user-level configuration */
{ config, lib, pkgs, user, ... }:

let
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
    ./packages.nix
    ./work
    ../brews/apps.nix
  ] ++ (modules.importAllModules ./modules) ++ (modules.importHomeModules ../brews);

  # App configurations are now in brews/shared-config.nix and imported automatically

  # secureEnv.onePassword = {
  #   enable = true;
    
  #   sessionVariables = {
  #     PRIVATE_GITHUB_TOKEN = {
  #       account = "my.1password.com";
  #       vault = "Private";
  #       item = "Github Token";
  #       field = "password";
  #     };
  #   };
  # };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    wallpaper.file = ./config/wallpaper/drwho-best.jpeg;

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
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.fantasque-sans-mono
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

    yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_dir_first = true;
        };
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config.global.log_filter = ''^(loading|using nix|error|deny|allow).*$'';
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

    # Comparable to jq / yq, but supports JSON, YAML, TOML, XML and CSV with zero runtime dependencies.
    dasel = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    git = {
      enable = true;
      userName = user.fullName;
      userEmail = user.email;
      githubUser = user.githubUser;

      workspaces = user.gitWorkspaces;
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      format = "$all$shell$shlvl$character";
      battery.disabled = true;
      dotnet.disabled = true;
      c.disabled = true;
      package.disabled = true;
      nodejs.disabled = true;

      directory = {
        style = "fg:31";
        repo_root_style= "bold fg:31";
        truncation_symbol = "../";
        truncation_length = 10;
        truncate_to_repo = false;
      };

      aws = { 
        symbol = "☁️ ";
        region_aliases = {
          ap-southeast-2 = "au";
          ca-central-1 = "ca";
        };
      };

      shell = {
        disabled = false;
        bash_indicator = "bash";
        zsh_indicator = "";
        format = "[$indicator]($style)";
        style = "white bold";
      };

      nix_shell = {
        format = "via [$symbol$state]($style) ";
        symbol = "❄️ ";
      };

      shlvl = {
        disabled = false;
        symbol = "↕️";
        format = "[\\($shlvl\\)]($style)";
      };
    };
  };

  programs.nushell = {
    enable = true;
    plugins = with pkgs.nushellPlugins; [
      hcl
      query
      polars
      highlight
    ];
  };

  programs.bash = {
    enable = true;
  };

  ### ZSH (TODO: Maybe Mmve to a module?)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # history.extended = true;

    # this is to workaround zsh syntax highlighting slowness on copy/paste
    # https://github.com/zsh-users/zsh-syntax-highlighting/issues/295#issuecomment-214581607
    initContent = ''
      zstyle ':bracketed-paste-magic' active-widgets '.self-*'
    '';

    shellAliases = {
      whereis = "function _whereis() { which \"$1\" | xargs realpath; }; _whereis";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "dirhistory"
        "docker-compose"
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
  home.stateVersion = "25.05";

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
