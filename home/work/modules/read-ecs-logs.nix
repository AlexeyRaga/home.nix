{ pkgs, config, lib, ... }:

let
  writeScriptDir = path: text:
    pkgs.writeTextFile {
      inherit text;
      executable = true;
      name = builtins.baseNameOf path;
      destination = "${path}";
    };

  readEcsLogs = pkgs.writeShellScriptBin "read-ecs-logs" ''
NETWORKS=$(warp-cli vnet)
CURRENT_NETWORK=$(echo "$NETWORKS" | grep 'Currently selected' | awk '{print $NF}')

if [ -z "$CURRENT_NETWORK" ]; then
    echo "You are currently not connected to any VPN. Please connect to a VPN using your Warp client"
    exit 1
fi

CURRENT_NETWORK_NAME=$(echo "$NETWORKS" | grep -A 1 "ID: $CURRENT_NETWORK" | grep 'Name:' | awk '{print $NF}')

export AWS_PROFILE=''${CURRENT_NETWORK_NAME%-vnet}
export AWS_DEFAULT_PROFILE=$AWS_PROFILE
export AWS_REGION=$(aws configure get region --profile $AWS_PROFILE)

# Check if logged in to AWS
if ! aws sts get-caller-identity &> /dev/null; then
  echo "You are not logged in to AWS."
  echo "Please run 'aws sso login --profile $AWS_PROFILE'"
  exit 1
fi

usage() {
    echo "Usage: read-ecs-logs [service-name]"
    echo "Read logs for a given ECS service."
    echo
    echo "Available services:"
    echo
    aws ecs list-services --cluster core --query 'serviceArns[*]' | jq -r '.[] | split("/") | .[-1]' | sort
    exit 1
}

if [ $# -eq 0 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  usage
fi

SERVICE_NAME=$1

LOGS_BUCKET=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n' | grep reliab)

DATE_PREFIX=$(date -u +"%Y/%m/%d")

LAST_FILE=$(aws s3api list-objects-v2 --bucket "$LOGS_BUCKET" --prefix "$SERVICE_NAME/$DATE_PREFIX" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output text)

aws s3 cp "s3://$LOGS_BUCKET/$LAST_FILE" -
  '';

  readEcsLogsCompletion = writeScriptDir "/share/zsh/site-functions/_read-ecs-logs" ''
    #compdef read-ecs-logs
    _perform_read_ecs_logs() {
      local NETWORKS=$(warp-cli vnet)
      local CURRENT_NETWORK=$(echo "$NETWORKS" | grep 'Currently selected' | awk '{print $NF}')

      if [ -z "$CURRENT_NETWORK" ]; then
          echo "You are currently not connected to any VPN. Please connect to a VPN using your Warp client"
          exit 1
      fi

      local CURRENT_NETWORK_NAME=$(echo "$NETWORKS" | grep -A 1 "ID: $CURRENT_NETWORK" | grep 'Name:' | awk '{print $NF}')

      local AWS_PROFILE=''${CURRENT_NETWORK_NAME%-vnet}
      local AWS_REGION=$(aws configure get region --profile $AWS_PROFILE)

      local -a services
      services=($(aws ecs --region $AWS_REGION --profile $AWS_PROFILE list-services --cluster core --query 'serviceArns[*]' | jq -r '.[] | split("/") | .[-1]'))
      
      compadd $services
    }

    compdef _perform_read_ecs_logs read-ecs-logs
  '';
in {
  home.packages = with pkgs; [
    awscli2
    readEcsLogs
    readEcsLogsCompletion
  ];
}
