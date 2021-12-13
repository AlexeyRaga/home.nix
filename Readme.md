# Home Manager Nix configuration

This Readme is currently MacOS-centric.
However, the configuration itself has been tried on Ubuntu and NixOS and it turns out to be working (not using `darwin-configuration.nix`, obviously, but using the whole `Home Manager` config.).

## Installation

It uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) to set up and manage the user's home environment.

0. Clone this repository as your local `~/.nixpkgs` </br>
    You should have `~/.nixpkgs/darwin-configuration.nix` available.

1. Set up your secrets:
   ```bash
    $ cp ~/.nixpkgs/home/secrets/default.nix.example ~/.nixpkgs/home/secrets/default.nix
    $ cp ~/.nixpkgs/home/work/secrets/default.nix.example ~/.nixpkgs/home/work/secrets/default.nix
   ```
   Edit both files. The first one represents "global" secrets, and the second one is for work-related secrets.

1. Install [Nix](https://nixos.org/download.html)
   ```bash
    $ sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Add `home-manager` channel:
   ```bash
    $ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    $ nix-channel --update
   ```
3. (Optionaly) Install [Homebrew](https://brew.sh/)
   ```
   $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent. com/Homebrew/install/HEAD/install.sh)"
   ```

3. Install [nix-darwin](https://github.com/LnL7/nix-darwin)
   ```
    $ nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
    $ ./result/bin/darwin-installer
   ```

At this point everything should be installed and the environment should be ready to rock.
Restart the shell if you haven't paid attention to the prompt :)

## Updating the configuration

Make changes to the configuration files and run `darwin-rebuild switch` to update the configuration.

## Note on integration with Homebrew

If `Homebrew` is installed, this configuration will manage `Homebrew` packages via [homebrew.nix](./homebrew.nix) file.
Use [homebrew.nix](./homebrew.nix) to specify which packages should be installed via `brew` and Nix will handle the rest.


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

### Keychain

`Keychain` allows to store passwords in Keychain populating it from `1Password`.

Example:

```nix
  keychain = {
    enable = true;

    from1Password = {
      githubToken = {
        vault = "Private";
        item = "GitHub";
        field = "token";

        # Optionaly: Expose the token as an env variable which value will be read from Keychain
        exportEnvVariable = "GITHUB_TOKEN";
      };
      };
    };
  };

```

**NOTE**: `Keychain` module will _not_ remove any passwords from Keychain. It will only populate it with passwords from 1Password and update existing ones.

### .NET

`dotnet.nix` module makes .NET SDK available for the machine. It

It also allows configuring extra Nuget sources, which is useful in setups with private nuget repositories.

Example:

```nix
  tools.dotnet = {
    enable = true;
    nugetSources = {
      bigBankGithub = {
        url = "https://nuget.pkg.github.com/BigBank/index.json";
        userName = secrets.github.userName;
        password = secrets.github.token;
      };
    };
  };
```
