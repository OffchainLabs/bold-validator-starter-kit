# Arbitrum BOLD Validator Starter Kit

This repository is for those in the community who wish to run a BOLD validator on the public testnet to see BOLD in action. In this repository, you will find two Docker Compose files for spinning up a BOLD validator for Arbitrum chains, in two different modes: honest and evil. 

The validator that gets deployed will be validating transactions on the public BOLD testnet and will: post to, monitor for, and challenge invalid state assertions on Ethereum Sepolia. In other words, this BOLD testnet is an L2. To simulate traffic on the testnet, a transaction spammer (1 txn/10s) is used. 

## Links

- [BOLD Gentle Introduction](https://docs.arbitrum.io/bold/bold-gentle-introduction)
- [Arbitrum Nitro](https://github.com/OffchainLabs/nitro)
- [BOLD Repository](https://github.com/OffchainLabs/bold)

The BOLD testnet is an L2 that uses Ethereum Sepolia as its parent chain. The L2 chain config can be found under [here](honest-validator/l2_chain_info.json)

BOLD Testnet URLs:

- Block explorer [https://bold-explorer.arbitrum.io/](https://bold-explorer.arbitrum.io/)
- Sequencer RPC [https://bold.arbitrum.io/rpc](https://bold.arbitrum.io/rpc)
- Sequencer Feed [wss://bold.arbitrum.io/feed](wss://bold.arbitrum.io/feed)

## Step 1: Prepare pre-requisites
- Install and start [Docker](https://docs.docker.com/engine/install/) locally 
- If on Linux, follow the [post-install documentation](https://docs.docker.com/engine/install/linux-postinstall/) for docker to allow you to run docker as a non-root user
- Install [docker compose standalone](https://docs.docker.com/compose/install/standalone/) and verify it is installed (you can verify this by running `docker compose version` which should return the version of Docker Compose you are running). You may need to give executable permissions to it `chmod +x /usr/bin/docker-compose` if running on Linux
- Install [Jq](https://jqlang.github.io/jq/download/)
- An **Ethereum Sepolia** testnet account with at least 150 Sepolia ETH to stake on assertions, and also open challenges. The base stake to become an assertion poster is 100 Sepolia ETH on this testnet. If you are looking to run a BOLD validator, we'd love to hear from you on the [Arbitrum Discord](https://discord.gg/arbitrum)
- An RPC connection to Ethereum Sepolia. You must run own Ethereum Sepolia node to avoid potential rate limits imposed by 3rd party providers
- Ensure your machine has, at minimum, 8 GB of RAM and 4 CPU cores (if using AWS, we recommend a `t3 xLarge`)

## Step 2: Define environment variables
The following environment variables are required to run the commands below:
- `SEPOLIA_ENDPOINT`: An Ethereum node RPC endpoint for running your validator. **If running a node on localhost on MacOS, this must be set to `http://host.docker.internal:$PORT`**
- `HONEST_PRIVATE_KEY` or `EVIL_PRIVATE_KEY`: an Ethereum private key **without a 0x prefix** as a hex string. For example, if your private key is `0xabc123`, please use `abc123`.
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

**Or build the Docker image yourself**

You can also build the Docker image from source

```
git clone https://github.com/OffchainLabs/nitro && cd nitro
git checkout sepolia-tooling-merge
git submodule update --init --recursive --force
```

Then
```
docker build /home/ultrainstinct/Desktop/nitro -t nitro-node-dev --target nitro-node-dev && docker tag nitro-node-dev:latest nitro-node-dev-testnode
```

Then you can use this image under `honest-validator/docker-compose.yml` or `evil-validator/docker-compose.yml`


## Step 4: Fund your validator 
Next, mint and fund your validator with the stake token on Sepolia (the stake token is an ERC20). If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where `<PORT>` is the port where its http server is running. By default, this is 8545.
```
./mint_stake_token.sh --private-key $PRIVATE_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```
By running this command, the ERC20 staking token will be minted using the Sepolia ETH. This will allow the validator to stake on assertions and open challenges to assertions it observes (and disagrees with).

100 Sepolia WETH is required to become an assertion poster on the testnet, and opening and resolving a single challenge claim by an adversary would cost around 50 Sepolia WETH.


## Step 5: Run your validator
You can choose to run either an honest or an evil BOLD validator, or both. If you are running a node on your localhost, make sure your `SEPOLIA_ENDPOINT` environment variable is set to: `http://host.docker.internal:<PORT>` where `<PORT>` is the port where its http server is running. By default, this is 8545.

### Honest Validator
To start your validator, run:
```
./validator.sh --private-key $HONEST_PRIVATE_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

### Or Run an Evil Validator
To start your validator, but in evil mode, simply run the same command as above but with the `--evil` flag:
```
./validator.sh --evil --private-key $EVIL_PRIVATE_KEY --eth-rpc-endpoint $SEPOLIA_ENDPOINT
```

Congratulations! You've now funded and started a BOLD validator. At first, there may be some `ERROR` log lines. Rest assured that this is expected at first as it takes some time for the node to catch up with the chain's latest state. This means that the node will attempt to post assertions and challenge observed assertions that it does not agree with, but will fail to do so until the node is synced up. You will know the node is synced up when you see log lines that contain messages such as: `"Successfully submitted assertion"`.

## Interpreting key log lines
Note that when running a validator, the use of the term `evil` and `honest` in the logs are _relative_ to your validator node. In other words, your validator will always consider assertions that it agrees with to be `honest` assertions. Likewise, any assertion that your validator node disagrees with is considered `evil`. 

Below are a few log lines that can help you follow along with any on-going challenges:
* `"Posting assertion for batch we agree with"` - posting of a state assertion that your node believes to be correct
* `"Disagreed with an observed assertion onchain"` - your validator has arrived at a state that is different from one that was asserted by another party on-chain
* `"Opening a challenge on an observed assertion"` - marks the beginning of a dispute over an asserted state between your node and another party
* `"Successfully submitted assertion"` - submission of an assertion as part of the multi-level, interactive dispute protocol
* `"Observed an evil edge created onchain from an adversary, will make necessary moves on it"` - your validator has observed that the counter party has made a move and will be responding with a bisection assertion next
* `"Now tracking challenge edge locally and making moves"` - your validator is now dissecting the history commitments as part of the multi-level, interactive dispute protocol
* `Computing subchallenge progress: 39.99% - 6553 of 16385 hashes needed stepSize=16384` - a log line indicting that your validator is now computing the hashes for a subchallenge 
* `"Updated edge timer"` - when the validator is finished making it's move, a "timer" is started so that if the counter party does not respond before the challenge period is over, the entity who made the last move will have their assertion confirmed automatically.
* `"Identified single step of disagreement at the execution of a block, ready for one-step fraud proof"` - indicates that your validator has reached the "one step proof" stage of the interactive challenge 
* `"Submitting one-step-proof to protocol"` - your validator is now submitting the one-step-proof to a smart contract on the parent chain (e.g. Ethereum) to use to verify if your assertion is correct (via execution of that single step)
* `"Confirmed assertion by challenge win"` - this log line indicates that a challenge over an asserted state has been resolved, with the honest party "winning" the dispute and confirming the asserted state. This happens after a one-step proof is submitted to Ethereum to determine the winner.
* `"Confirmed assertion by time` - this happens when an assertion, made as part of a challenge, gets confirmed automatically because the counter party failed to submit a rival challenge assertion within the fixed challenge period time window.
* `"Assertion with hash 0xf9be2a92 needs at least 50150 blocks before being confirmable, waiting for 167h10m0s"` - this log line indicates that a given assertion will be confirmed automatically via time if there are no challenges open against it
* `"Observed an honest challenge edge created onchain, now tracking it locally"` - this log line gets printed when your validator observes a challenge edge that it agrees on - no challenge will be opened since it agrees on the asserted state made by the other party.
* `"Modified tx value in evil validator with value 7777777000000000, to value 7777778000000000"` - a log line only printed when running an evil validator, this basically indicates that the evil validator has manipulated a txn that would result in an invalid state (intentionally)
* `"could not confirm one step proof against protocol"` - as an evil validator, this log line indicates that you have *lost* the dispute via confirmation by the parent chain. This basically means that your asserted state, at the step of dispute, was proven to be invalid by the referee contract on the parent chain

## Troubleshooting and what some log lines mean:
There may be periods of time where there are no logs being printed when running an honest validator. This is normal and totally fine because it means that there are no invalid state assertions observed, and therefore, no on-going challenges. If useful, the RPC port for the honest validator is `8247` while the RPC port for the evil validator is `8947`.

Arbitrum BOLD is currently in `alpha` and is still being actively developed on. As such, below are the explanation behind a few errors and log lines that may arise during testing. Many of the log lines below are expected and indicate healthy, expected behavior of your BOLD validator.
* `Could not succeed function after retries package=retry retryCount=1 err="chain catching up` - This is expected when first starting up your validator. As mentioned earlier, this log line simply indicates that the validator is not yet fully synced up with the latest state of the testnet. This should eventually disappear after some time (~5 minutes or sooner)
* `Could not succeed function after retries package=retry retryCount=1 err="could not add edge to challenge tree: could not check history commitment agreement for edge: 0xd37b29c62d55d8a6b2fe8f288b9e6a5914bf817edba1af5af894d8b9cb7e985a: accumulator not found: no metadata for batch 5447"` - while rare, this most likely is a result of the validator node not being synced up yet to the latest state of the testnet. The retry logic will eventually ensure that your validator can succesfully add edges to the challenge tree and check history committments. 
* `InboxTracker` - posted at regular intervals, this log line is simply printing some metadata about the current state
* `No available batch to post as assertion, waiting for more batches` - because validators will try to post an assertion every hour, there may be times where there is not enough batches to post an assertion. This could be because of a variety of reasons, such as low txn volume. The retry logic will ensure that eventually an assertion gets posted successfully once there are enough batches to do so.
* `error opening parent chain wallet        path=/home/user/.arbitrum/local/wallet account= err="invalid hex character 'x' in private key"` - this log line will get printed if the private key you provide contains the `0x` prefix. Please remove the `0x` prefix before supplying the `validator.sh` script with the key!
* `err="invalid block range params"` or `err="unsupported block number"` - this can be resolved by wiping the validator database (instructions below)
* `err="execution reverted: ERC20: insufficient allowance"` or `error="could not create assertion: test execution of tx errored before sending payable tx: execution reverted: ERC20: insufficient allowance"` - this happens when your validator has exhausted the entire supply of the ERC20 staking token minted when you ran `./mint_stake_token.sh`. Simply re-run the same command to mint more staking tokens
* `err="execution reverted: PREV_NOT_LATEST_CONFIRMED"` - this is normal, no need to worry, because most of the tx or estimation failed with `PREV_NOT_LATEST_CONFIRMED` is because many validators race to confrim the same rblock while only one can succeed so others will get failed

### How to wipe the validator database

If the node db gets corrupted for some reason (bad shutdown, for example), you may need to wipe the node's database. To do so, use the below commands (depending on the type of validator you're running):
```
docker volume rm $(docker volume ls -q | grep "honest-validator") 2>/dev/null
docker volume rm $(docker volume ls -q | grep "evil-validator") 2>/dev/null
```
