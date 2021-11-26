# Home Manager Nix configuration

Currently MacOS-centric

## Requirements

1. Install [Nix](https://nixos.org/download.html)
2. Install [nix-darwin](https://github.com/LnL7/nix-darwin)
3. Add `home-manager` channel:
   ```bash
    $ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

    $ nix-channel --update
   ```

## Usage

1. Clone this repository as your (`~/.nixpkgs`).
   You should have `~/.nixpkgs/darwin-configuration.nix` and `~/.nixpkgs/home/` in place

2. Create a secret file `secrets/default.nix` in the root of this repository. It should have the following structure:

    ```nix
    {
      github = {
        userName = "<github-user-name>";
        token = "<github-api-token>";
      };

      aws = {
        profiles = [];
      };
    }
    ```

    When modifying the configuration and adding more stuff, this file could be a good starting point, alternatively more files can be added to `secrets` directory (which is git ignored for obvious reasons).

3. Modify as you wish.

4. Ussue `darwin-rebuild switch` and enjoy your life.

## Modules overview

A short overview of modules and what they can download

### Git

`git.nix` module installs and enables `Git and creates a global configuration (username/email/github user name).

It also allows configuring "workspaces": folders that should have their own alterations of git configuration.
For example, email addresses that are used for git commits can be different for private and work-related projects.

Example:

```nix
  tools.git = {
    enable = true;
    userName = "Donald Duck";
    userEmail = "donald.duck@gmail.com";
    githubUser = secrets.github.userName;

    workspaces = {
      "src/work" = {
        user = { email = "donald.duck@bigbank.com"; };
        core = { autocrlf = true; };
      };
      "src/charity" {
        user = { email = "donald.duck@charity-works.net"; };
      };
    };
  };
```


### .NET

`dotnet.nix` module makes .NET SDK available for the machine. It

It also allows configuring extra Nuget sources, which is useful in setups with private nuget repositories.

Example:

```nix
  tools.dotnet = {
    enable = true;
    nugetSources = [
      { name = "github.com";
        url = "https://nuget.pkg.github.com/BigBank/index.json";
        userName = secrets.github.userName;
        password = secrets.github.token;
      }
    ];
  };
```
