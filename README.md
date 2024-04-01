# Arbitrum BOLD Validator Starter Kit

This repository contains two docker compose setups for validators in Arbitrum BOLD. Both an honest and evil validator can participate in BOLD challenges on Ethereum sepolia.

## Requirements

- [Docker and Docker Compose](https://docs.docker.com/engine/install/)
- [Jq](https://jqlang.github.io/jq/download/)
- An **Ethereum Sepolia** testnet account with funds. We recommend at least 0.5 Sepolia ETH. Testnet faucets are available online, such as Alchemy's [here](https://sepoliafaucet.com/)

## Environment Variables

These env vars are required to run the commands below:

- `SEPOLIA_ENDPOINT`: An Ethereum node RPC endpoint for running your validator. We recommend a local node. **If running a node on localhost on MacOS, this must be set to `ws://host.docker.internal:$PORT` or `http://host.docker.internal:$PORT` for http**
- `HONEST_PRIV_KEY`: an Ethereum private key **without a 0x prefix** as a hex string

If you want to run an evil validator instead, use the following for your private key:

- `EVIL_PRIV_KEY`: an Ethereum private key **without a 0x prefix** as a hex string

## Running

You can choose to run either an honest or an evil validator on Ethereum sepolia. Note that your validator must have a special testnet Weth ERC20 token to participate in challenges and must have approved the rollup and challenge manager contracts to spend it.

You will also **need an Ethereum Sepolia RPC connection**. We recommend running your own Sepolia testnet node, as services such as infura run into rate limits.

### Pull the Docker Images

```
docker pull ghcr.io/rauljordan/nitro:bold && docker pull ghcr.io/rauljordan/bold-utils:latest
```

### Honest Validator

First, fund your validator with the stake token needed on Sepolia. If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where <PORT> is the port where its http server is running. By default, this is 8545.

```
./mint_stake_token.sh --private-key $HONEST_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

Then, start your validator

```
./validator.sh --private-key $HONEST_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

### Evil Validator

First, fund your validator with the stake token needed on Sepolia. If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where <PORT> is the port where its http server is running. By default, this is 8545.

```
./mint_stake_token.sh --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

Then, start your validator

```
./validator.sh --evil --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

## How Evil Validators Work

Evil validators at the moment intercept all Arbitrum deposit transactions to the inbox that have a value of 1M gwei, or 0.001 ETH. To modify the amount to intercept, change **all instances** of `evil-intercept-deposit-gwei` in your `evil-validator/evil_validator_config.json` to a different amount of gwei. If you want to bridge some ETH to the inbox with a value that will be intercepted, you can run:

```
./bridge_eth.sh --gwei-to-deposit 1000000 --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

The above will send an ETH deposit to an Arbitrum inbox contract of 1M gwei, which is the default value the evil validator is configured to maliciously tweak.
