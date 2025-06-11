# Home Manager Nix configuration

It uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) to set up and manage the user's home environment.

This Readme is currently MacOS-centric.

## Installation

1. Install [Nix](https://nixos.org/download.html)
   ```bash
    $ sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. (MacOS only) Install [Homebrew](https://brew.sh/)
   ```
   $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Clone this repository as your local `~/.nixpkgs` or,better, have your own fork.</br>

4. :exclamation: Edit `flake.nix` and specified your own user details.

5. :warning: Work config ([home/work/default.nix](./home/work/default.nix)) requires some passwords to be found in `1Password`. Review the config and update if needed. 

6. Add your changes to `git`:
   ```bash
    $ git add .
   ```
   When working with `Nix` flakes it is essential, 
   because it annoyingly ignores files that are not tracked by `git`.

7. Switch the profile:
   ```bash
    $ sudo nix run --extra-experimental-features 'nix-command flakes' nix-darwin/master#darwin-rebuild -- switch --flake .
   ```

At this point everything should be installed and the environment should be ready to rock.
Restart the shell if you haven't paid attention to the prompt :)

After your first successfful switch, you should be able to use just
```bash
$ sudo darwin-rebuild switch --flake .
```

## Updating the configuration

Make changes to the configuration files and add them to `git`.
Then run `sudo darwin-rebuild switch --flake .` to switch to the updated configuration.

## Note on integration with Homebrew

This configuration manages some MacOS applications as `Homebrew` packages via [brews/apps.nix](./brews/apps.nix) file.
Use [brews/apps.nix](./brews/apps.nix) to specify which packages should be installed via `brew` and Nix will handle the rest.

## Your system configuration

A couple of entry points to tune your config:

- [home/packages.nix](./home/packages.nix) - Packages to install
- [home/default.nix](./home/default.nix) - Your main home "configuration": what programs and services are enabled, how shell is set up, etc.

MacOS specific:

- [darwin/preferences.nix](./darwin/preferences.nix) - Global MacOS preferences and settings
- [darwin/dock.nix](./darwin/dock.nix) - Configure your dock

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

### SecureEnv

`SecureEnv` allows to store secrets securely populating them from password managers (currently only `1Password`) with an ability to export
these secrets as environment variables and ssh keys in ssh-agent.

The reason for not exporting them from password managers directly is that they only keeps a session open for a short period of time,
which means that users will be asked to re-authenticate often.

Instead, secrets are copied to `Keychain` (on MacOS) or `Keyring` (on Linux) and then used to source env variables.
This way secrets are never stored on disk unencrypted but can still be made conveniently available to the user as environment variables.

Example:

```nix
  secureEnv.onePassword = {
    enable = true;
    sessionVariables = {
      # This env variable will be set up for user's session
      GITHUB_TOKEN = {
        account = "my.1password.com";
        vault = "Private";
        item = "Github";
        field = "token";
      };
    };
    sshKeys = {
      # These keys will be set up for SSH
      staging_pem = {
        account = "mycompany.1password.com";
        vault = "Dev - Shared DevOps";
        item = "staging-ssh-key";
        field = "notes";
      };
      test_pem = {
        account = "mycompany.1password.com";
        vault = "Dev - Shared DevOps";
        item = "test-ssh-key";
        field = "notes";
      };
    };
  };

```

**NOTE**: `Secret Store` module will _not_ remove any passwords from `Keychain`/`Keyring`. It will only сopy passwords and update existing ones.

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
        userName = "%GITHUB_USERNAME%";
        password = "%GITHUB_TOKEN%";
      };
    };
  };
```

### AWS

AWS can be configured via `tools.aws` module.

AWS can have statically defined profiles, and SAML profiles (using Google as ID Provider) such as:

```nix
  tools.aws = {
    enable = true;

    profiles = {
      default = {
        accessKeyId = "AKIAIOSFODNN7EXAMPLE";
        secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
      };
    };

    ssoProfiles = {
      test = {
        sso_start_url = "https://my-company.awsapps.com/start";
        sso_account_id = "123456789012";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };

      prod = {
        sso_start_url = "https://my-company.awsapps.com/start";
        sso_account_id = "210987654321";
        sso_role_name = "admin";
        sso_region = "ap-southeast-2";
        region = "ap-southeast-2";
      };
    };
  };
```

When `ssoProfiles` are defined, an AWS SDK `aws sso login --profile <name>` command can be used to log in to AWS.
