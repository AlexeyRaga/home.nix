# This overlay adds packages from flake inputs
# It runs first (00- prefix) so other overlays can override if needed

self: super: 
let
  inputs = super.inputs or {};
  system = super.system;
in {
  # Example: Add packages from other flake inputs here
  # helix = inputs.helix.packages.${system}.default or super.helix;
  
  # Example: Pin specific packages from stable
  # terraform = inputs.nixpkgs-stable.legacyPackages.${system}.terraform or super.terraform;
}