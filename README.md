# Arbitrum BOLD Validator Starter Kit

This repository is for those in the community who wish to run a BOLD validator on the public testnet to see BOLD in action. Make sure to also checkout the [BOLD testnet status page](https://status-bold.vercel.app/) to see the number of on-going challenges and validators on the network! In this repository, you will find two Docker Compose files for spinning up a BOLD validator for Arbitrum chains, in two different modes: honest and evil. 

The validator that gets deployed will be validating transactions on the public BOLD testnet and will: post to, monitor for, and challenge invalid state assertions on Ethereum Sepolia. In other words, this BOLD testnet is an L2. To simulate traffic on the testnet, a transaction spammer (1 txn/10s) is used. 

## Step 1: Prepare pre-requisites
- Install and start [Docker](https://docs.docker.com/engine/install/) locally and ensure you have Docker Compose (you can verify this by running `docker compose version` which should return the version of Docker Compose you are running)
- Download and install [Jq](https://jqlang.github.io/jq/download/)
- An **Ethereum Sepolia** testnet account with funds. We recommend at least 0.5 Sepolia ETH. Testnet faucets are available online, such as Alchemy's [here](https://sepoliafaucet.com/)
- An RPC connection to Ethereum Sepolia. We recommend a local node to avoid potential rate limits imposed by 3rd party providers
- Ensure your machine has, at minimum, 8 GB of RAM and 4 CPU cores (if using AWS, we recommend a `t3 xLarge`)

## Step 2: Define environment variables
The following environment variables are required to run the commands below:
- `SEPOLIA_ENDPOINT`: An Ethereum node RPC endpoint for running your validator. **If running a node on localhost on MacOS, this must be set to `ws://host.docker.internal:$PORT` or `http://host.docker.internal:$PORT` for http**
- `HONEST_PRIV_KEY` and/or `EVIL_PRIV_KEY`: an Ethereum private key **without a 0x prefix** as a hex string. For example, if your private key is `0xabc123`, please use `abc123`.
    - Note: You may use the same private key for either of these variables if you are only running 1 validator. If you plan to run 2 validators simultaneously, it is recommended that you use 2 different private keys.

## Step 3: Clone the repository & pull Docker images
Be sure to clone this repository locally and start from the working directory:
```bash
git clone https://github.com/OffchainLabs/bold-validator-starter-kit.git
cd bold-validator-starter-kit
```

Next, pull the Docker images down:
```bash
docker pull ghcr.io/rauljordan/nitro:bold && docker pull ghcr.io/rauljordan/bold-utils:latest
```

## Step 4: Running
You can choose to run either an honest or an evil BOLD validator, or both. 

### Honest Validator
First, fund your validator with the stake token needed on Sepolia. If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where <PORT> is the port where its http server is running. By default, this is 8545.
```
./mint_stake_token.sh --private-key $HONEST_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```
By running this command, the honest validator will be granted approval to spend the Ethereum Sepolia testnet ETH from the account controlled by the private key you provided. This will allow the validator to stake on assertions and open challenges to invalid assertions it observes.

Then, start your validator:
```
./validator.sh --private-key $HONEST_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

Congratulations! You've now funded and started an honest BOLD validator. At first, there will be many log lines - including some `ERROR` log lines. Rest assured that this is expected at first as it takes some time (~5 minutes) for the node to catch up with the chain's latest state. This means that the node will attempt to post assertions and challenge observed assertions that it does not agree with, but will fail to do so until the node is synced up. You will know the node is synced up when you see log lines that contain messages such as: `"Posting assertion with retrieved state"` and `"Observed edge from onchain event"`.

### Evil Validator
Similar to what you did with the honest validator, fund your evil validator with the stake token needed on Sepolia. If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where <PORT> is the port where its http server is running. By default, this is 8545.
```
./mint_stake_token.sh --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```
By running this command, the evil validator will be granted approval to spend the Ethereum Sepolia testnet ETH from the account controlled by the private key you provided. This will allow the validator to stake on assertions and open challenges to invalid assertions it observes.

Then, start your validator *with the `--evil` flag:
```
./validator.sh --evil --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

## How Evil Validators Work
Evil validators at the moment intercept all Arbitrum deposit transactions to the inbox that have a value of 1M gwei, or 0.001 ETH. To modify the amount to intercept, change **all instances** of `evil-intercept-deposit-gwei` in your `evil-validator/evil_validator_config.json` to a different amount of gwei. If you want to bridge some ETH to the inbox with a value that will be intercepted, you can run:

```
./bridge_eth.sh --gwei-to-deposit 1000000 --private-key $EVIL_PRIV_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

The above will send an ETH deposit to an Arbitrum inbox contract of 1M gwei, which is the default value the evil validator is configured to maliciously tweak.

#### Troubleshooting and what some log lines mean:
Arbitrum BOLD is currently in `alpha` and is still being actively developed on. As such, below are the explanation behind a few errors and log lines that may arise during testing. Many of the log lines below are expected and indicate healthy, expected behavior of your BOLD validator.
* `Could not succeed function after retries package=retry retryCount=1 err="chain catching up` - This is expected when first starting up your validator. As mentioned earlier, this log line simply indicates that the validator is not yet fully synced up with the latest state of the testnet. This should eventually disappear after some time (~5 minutes or sooner)
* `Could not succeed function after retries package=retry retryCount=40 err="could not add edge to challenge tree: could not check history commitment agreement for edge: 0xd37b29c62d55d8a6b2fe8f288b9e6a5914bf817edba1af5af894d8b9cb7e985a: accumulator not found: no metadata for batch 5447"` - while rare, this most likely is a result of the validator node not being synced up yet to the latest state of the testnet. The retry logic will eventually ensure that your validator can succesfully add edges to the challenge tree and check history committments. 
* `InboxTracker` - posted at regular intervals, this log line is simply printing some metadata about the current state
* `Posting assertion with retrieved state` - this essentially means that your validator has run the transaction data through the State Transition Function (STF), arrived at a state (referred to as a "retrieved state"), and is about to post the state as an assertion to Ethereum Sepolia.
* `"Waiting before submitting challenge on assertion" delay=0` - log line emitted shortly before the validator submits a challenge to an assertion that the validator disagrees with. You'll notice that the delay is set to 0 but on mainnet this value will be non-zero to prevent multiple honest parties from submitting a challenge to the same invalid assertion simultaneously.
* `Challenge configs` - a line printed to show the configurations and metadata with which the validator will use in the soon-to-be-posted challenge assertion 
* `Submitted latest L2 state claim as an assertion to L1` - succesfully submitted a state assertion to the underlying L1 (in this case, Ethereum Sepolia)
* `Disagreed with execution state from observed assertion` - the validator node has concluded that an observed state assertion does not match with what was computed locally using the same inputs, therefore setting the stage for a challenge
* `Updated block challenge root edge inherited timer` - indicating a move has been made and that the validator is now updating the timer for the particular branch of the challenge tree
* `Subchallenge machine hash progress: 25.00% - 4096 of 16385 leaves computed` - progress of the bisection of a parent edge to a child edge
* `Creating subchallenge edge` - creation of a child edge
* `Created subchallenge edge` - creation of a child edge
* `Setting up validation    stage="computing state"    current=131,862 target=133,362` - log line(s) indicating that the validator is computing the steps between two states
* `Observed edge from onchain event"` - log line simply indicating that the validator node has observed an on-going challenge
* `Tracking edge` - the validator is following an observed challenge
* `Root level edge for challenged assertion already exists, skipping move` - your honest validator may attempt to challenge an already-challenged assertion at the root level. If this happens, the validator will skip making a move (because it does not need to).
* `Adding verified honest edge to honest edge tree` - log line indicating that your validator has bisected its asserted state and is adding what it believes to be the honest (but not yet confirmed) child edge to it's "tree" of edges (i.e. parent edges and their corresponding children edges).
* `No available batch to post as assertion, waiting for more batches` - because validators will try to post an assertion every hour, there may be times where there is not enough batches to post an assertion. This could be because of a variety of reasons, such as low txn volume. The retry logic will ensure that eventually an assertion gets posted successfully once there are enough batches to do so.
