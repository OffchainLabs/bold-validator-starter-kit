#!/bin/bash

# Initialize variables
PRIVATE_KEY=""
ETH_RPC_ENDPOINT=""
EVIL_MODE=false
CONFIG_FILE="validator_config.json" # Specify your JSON config file name

# Function to show usage
usage() {
    echo "Usage: $0 --private-key <private-key> --eth-rpc-endpoint <eth-rpc-endpoint> [--evil]"
    exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --private-key) PRIVATE_KEY="$2"; shift ;;
        --eth-rpc-endpoint) ETH_RPC_ENDPOINT="$2"; shift ;;
        --evil) EVIL_MODE=true ;;
        *) usage ;;
    esac
    shift
done

# Check required arguments
if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$ETH_RPC_ENDPOINT" ]]; then
    usage
fi

# Define the directory based on mode
VALIDATOR_DIR="honest-validator"
if [ "$EVIL_MODE" = true ]; then
    VALIDATOR_DIR="evil-validator"
    CONFIG_FILE="evil_validator_config.json"
fi

# Change to the validator directory
cd "$VALIDATOR_DIR"

# Edit the JSON configuration file
jq --arg pk "$PRIVATE_KEY" --arg ep "$ETH_RPC_ENDPOINT" \
   '.node.staker.["parent-chain-wallet"]."private-key" = $pk |
    .["parent-chain"].connection.url = $ep' "$CONFIG_FILE" > tmp.$$ && mv tmp.$$ "$CONFIG_FILE"

# Verify that the JSON file was edited
if [ $? -ne 0 ]; then
    echo "Error: Failed to update $CONFIG_FILE"
    exit 1
fi

# Stop all running containers before deleting volumes
docker-compose down

# docker volume rm $(docker volume ls -q | grep "${VALIDATOR_DIR}") 2>/dev/null

# Start up the services with docker-compose
echo "Validator ($VALIDATOR_DIR) is now starting."

docker-compose up -d && docker-compose logs -f

# Check if docker-compose started correctly
if [ $? -ne 0 ]; then
    echo "Error: docker-compose up failed"
    exit 1
fi

