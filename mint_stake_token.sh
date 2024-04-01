#!/bin/bash

SEPOLIA_ENDPOINT=""
PRIV_KEY=""
BUMP_PRICE_PERCENT=""

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
        --bump-price-percent)
        BUMP_PRICE_PERCENT="$2"
        shift # past argument
        shift # past value
        ;;
        *)
        shift # past argument
        ;;
    esac
done

# Check if the required arguments are set
if [ -z "$SEPOLIA_ENDPOINT" ] || [ -z "$PRIV_KEY" ]; then
    echo "Missing required arguments. Usage: $0 --eth-rpc-endpoint SEPOLIA_ENDPOINT --private-key PRIV_KEY [--bump-price-percent BUMP_PRICE_PERCENT]"
    exit 1
fi

JSON_FILE="honest-validator/l2_chain_info.json"

# Extracting the rollup, stake token, and inbox addresses using jq
ROLLUP_ADDR=$(jq -r '.[0].rollup.rollup' $JSON_FILE)
STAKE_TOKEN_ADDR=$(jq -r '.[0].rollup."stake-token"' $JSON_FILE)

docker pull ghcr.io/rauljordan/bold-utils:latest

# Running the Docker command
docker run --network=host ghcr.io/rauljordan/bold-utils:latest mint-stake-token \
 --validator-priv-keys=$PRIV_KEY \
 --l1-endpoint=$SEPOLIA_ENDPOINT \
 --rollup-address=$ROLLUP_ADDR \
 --stake-token-address=$STAKE_TOKEN_ADDR \
 --bump-price-percent=${BUMP_PRICE_PERCENT:-100}