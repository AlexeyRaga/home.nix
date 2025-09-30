{
  description = "Home-manager darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv/v1.8";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, devenv }: 
  let
    # Import modules lib for overlay discovery
    modules = import ./lib/modules.nix { lib = nixpkgs.lib; };
    
    # Create a special overlay that adds flake inputs to pkgs
    inputsOverlay = final: prev: {
      inputs = inputs;
    };
    
    # Auto-discover all overlays from the overlays directory
    overlays = [ inputsOverlay ] ++ (modules.discoverOverlays ./overlays);
    
    # Apply overlays to create a customized pkgs
    pkgs = import nixpkgs {
      system = "aarch64-darwin";
      inherit overlays;
      config.allowUnfree = true;
    };
    
    # User configuration - define your user details here
    user = {
      name        = "alexey";
      fullName    = "Alexey Raga";
      email       = "alexey.raga@gmail.com";  # Replace with your actual email
      home        = "/Users/alexey";
      shell       = "zsh";
      hostname    = "Alexeys-MacBook-Pro";  # System hostname for nix-darwin
      
      # Git-specific configurations
      githubUser  = "AlexeyRaga";
      gitWorkspaces = {
        "src/ep" = {
          user = {
            email = "alexey.raga@educationperfect.com";
            name = "AlexeyRaga";
          };
          core = { autocrlf = "input"; };
        };
        # Add more workspaces here as needed
        # "src/personal" = {
        #   user = {
        #     email = "alexey.raga@gmail.com";
        #     name = "Alexey Raga";
        #   };
        # };
      };
    };
  in
  {
    darwinConfigurations.${user.hostname} = nix-darwin.lib.darwinSystem {
      inherit pkgs;
      specialArgs = { inherit inputs user; };
      modules = [
        ./darwin-configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user.name} = ./home;
          home-manager.extraSpecialArgs = { inherit inputs user; };
        }
      ];
    };
  };
}
