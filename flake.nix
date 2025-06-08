{
  description = "Home-manager darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs }: 
  let
    # User configuration - define your user details here
    user = {
      name        = "alexey";
      fullName    = "Alexey Raga";
      email       = "alexey.raga@gmail.com";  # Replace with your actual email
      home        = "/Users/alexey";
      shell       = "zsh";
      
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
    darwinConfigurations."Alexeys-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs user; };
      modules = [
        ./darwin-configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useUserPackages = true;
          home-manager.users.${user.name} = ./home;
          home-manager.extraSpecialArgs = { inherit inputs user; };
        }
      ];
    };
  };
}
