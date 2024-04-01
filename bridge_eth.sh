#!/bin/bash


SEPOLIA_ENDPOINT=""
PRIV_KEY=""
GWEI_TO_DEPOSIT=""

# Parsing command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --eth-rpc-endpoint)
        SEPOLIA_ENDPOINT="$2"
        shift # past argument
        shift # past value
        ;;
        --private-key)
        PRIV_KEY="$2"
        shift # past argument
        shift # past value
        ;;
        --gwei-to-deposit)
        GWEI_TO_DEPOSIT="$2"
        shift # past argument
        shift # past value
        ;;
        *)
        shift # past argument
        ;;
    esac
done

# Check if the required arguments are set
if [ -z "$SEPOLIA_ENDPOINT" ] || [ -z "$PRIV_KEY" ] || [ -z "$GWEI_TO_DEPOSIT" ]; then
    echo "Missing required arguments. Usage: $0 --eth-rpc-endpoint SEPOLIA_ENDPOINT --private-key PRIV_KEY --gwei-to-deposit GWEI_TO_DEPOSIT"
    exit 1
fi

JSON_FILE="honest-validator/l2_chain_info.json"

# Extracting the rollup, stake token, and inbox addresses using jq
INBOX_ADDR=$(jq -r '.[0].rollup."inbox"' $JSON_FILE)

docker pull ghcr.io/rauljordan/bold-utils:latest

# Running the Docker command
docker run --network=host ghcr.io/rauljordan/bold-utils:latest bridge-eth \
 --validator-priv-keys=$PRIV_KEY \
 --l1-endpoint=$SEPOLIA_ENDPOINT \
 --inbox-address=$INBOX_ADDR \
 --gwei-to-deposit=$GWEI_TO_DEPOSIT