{ pkgs, config, lib, ... }:

let
  dockerLoginScript = pkgs.writeShellScriptBin "docker-login" ''
      set -euo pipefail
      
      echo "🐳 Logging into AWS ECR..."
      if ! ${pkgs.awscli2}/bin/aws sts get-caller-identity --profile ecr >/dev/null 2>&1; then
        echo "❌ AWS authentication required. Please log in using: aws sso login --profile ecr"
        echo -n "Would you like to log in now? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
          echo "🔑 Logging in to AWS SSO..."
          if aws sso login --profile ecr; then
            echo "✅ Successfully logged into AWS SSO!"
          else
            echo "❌ Failed to log into AWS SSO"
            exit 1
          fi
        else
          echo "❌ AWS authentication required to proceed"
          exit 1
        fi
      else
        echo "✅ AWS authentication verified"
      fi

      echo "🔐 Getting ECR login token and logging into Docker..."
      if ${pkgs.awscli2}/bin/aws ecr get-login-password --region ap-southeast-2 --profile ecr | ${pkgs.docker}/bin/docker login --username AWS --password-stdin 058337015204.dkr.ecr.ap-southeast-2.amazonaws.com >/dev/null; then
        echo "✅ Successfully logged into AWS ECR!"
      else
        echo "❌ Failed to log into AWS ECR"
        exit 1
      fi
  '';
in {
  home.packages = with pkgs; [
    awscli2
    docker
    dockerLoginScript
  ];
}
