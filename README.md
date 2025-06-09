![Logo](./logo.png)

# Compound Streamer repository using Hardhat and Foundry

## Installation

Prerequisites: install [Node.js](https://nodejs.org/en/download/package-manager) 22.10+ with `pnpm` and [Visual Studio Code](https://code.visualstudio.com/download).

Open [the root of the project](./) using Visual Studio Code and install all the extensions recommended by notifications of Visual Studio Code, then restart Visual Studio Code.

Open the terminal and run the command below to install all the dependencies and prepare the project:

```shell
pnpm i
```

Run to view commands:

```shell
pnpm run
```

## Some unsorted notes

### Commands

- `pnpm coverage` shows all coverage and `pnpm test` runs all Hardhat and Foundry tests.
- `pnpm testh:vvv test/SomeContract.ts` and `pnpm testf -vvv --mc SomeContractTests` show details about events, calls, gas costs, etc.
- `pnpm coveragef:sum` show a coverage summary with branches for Foundry.

### Environment variables

The project can properly work without the \`.env\` file, but supports some variables (see `.env.details` for details). For example:

- `BAIL=true` to stop tests on the first failure.
- `EVM_VERSION="default"` and `HARDFORK="default"` if you would not like to use Prague, but would like Hardhat to behave by default.
- `VIA_IR=false` to disable IR optimization. You may also need to disable it in `.solcover.js` if compilation issues when running coverage.
- `COINMARKETCAP_API_KEY` and `ETHERSCAN_API_KEY` if you would like to see gas costs in dollars when running `pnpm testh:gas`.

### VS Code

- The `Watch` button can show/hide highlighting of the code coverage in the contract files after running `pnpm coverage`. The button is in the lower left corner of the VS Code window and added by `ryanluker.vscode-coverage-gutters`.

- Open the context menu (right-click) in a contract file, after running `pnpm coverage`, and select "Coverage Gutters: Preview Coverage Report" (or press Ctrl+Shift+6) to open the coverage HTML page directly in VS Code.

- Start writing `ss` in Solidity or TypeScript files to see some basic snippets.

## Troubleshooting

Run to clean up the project:

```shell
pnpm run clean
```

Afterwards, try again.

## TL;DR

[Streamer.sol](./contracts/Streamer.sol) - The Streamer smart contract is implemented for linear streaming of a native asset's value in the form of another ERC-20 token (streaming asset) to a recipient over a specified time period. It supports `AggregatorV3Interface` to convert between the native and streaming assets based on real-time USD prices, supporting price slippage for streaming asset.

Key functionalities:

    Stream creation and initialization

    Accrual and claim of streaming tokens

    Stream termination with notice period

    Rescue of non-streaming tokens

    Sweeping of unclaimed tokens before initialization and after stream ends

This contract is typically used for scheduled payments or vesting mechanisms with off-chain enforcement and real-time pricing.

[StreamerFactory.sol](./contracts/StreamerFactory.sol) - The Streamer Factory is a smart contract that enable the deployment of new Streamer instances using Create2. The contract allows customazible parameters such as streaming and native assets, price oracles, slippage, cooldowns, and durations during each deployment of Streamer. The Factory allows users to safely and predictably deploy Streamer contracts.

## Examples

##### Example 1. Distribute 1M worth of USDC in COMP

There is a need to distribute 1 million USDC worth of Comp tokens over 1-year period. Assuming that the price of COMP is $40 and 1 USDC = 1 USD:

```
deployFactory(
0xc00e94cb662c3520282e6f5717214004a7f26888, // Address of COMP
0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, // Address of USDC
0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5, // a valid COMP/USD Price Feed
0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6, // a valid USDC/USD Price Feed
<RETURN_ADDRESS>,
<RECIPIENT_ADDRESS>,
1000000000000, // $1M with 6 decimals (Minimal required decimals)
<SLIPPAGE>,
<CLAIM_COOLDOWN>,
<SWEEP_COOLDOWN>,
31536000, // seconds in 365 days, representing stream duration
2592000 // seconds in 30 daysm representing minimal notice period
)
```

The Stream Creator is the msg.sender.
**Example 1.1.** The price of COMP has changed
2 month has passed meaning that ~ 60 \* 2379 = 142740 USDC has unlocked. If the user claims right away, he will be able to claim 142740 / $40 = 3568,5 Comp. The user decides to wait and the price of Comp drops and now equal to $35. Now the user claims and receives approximately 142740 / $35 = 4078,2 Comp.

**Example 1.2.** Stream creator sweep COMP.
The Stream Creator decides to terminate the stream with a minimal notice period (In this case, 1 month).

```
terminateStream(0)
```

The user is still eligible to claim tokens for passed 5 month. Streaming asset continue to linearly accrue over the notice period. At the end of the Stream, the user is able to claim 6 _ 30 _ 2379 = 428220 USDC or 428220 / $40 = 10705,5 Comp. The user can still call:

```
claim()
```

Once the notice period has passed, the stream creator is able to sweep the remaining token by calling

```
sweepRemaining()
```

All remaining COMP tokens are sent to the `returnAddress`.

##### Example 2. Distribute 1M worth of USD in COMP

There is a need to distribute 1M worth of USD in Comp tokens. Assuming that the price of COMP is $40:
The following parameters should be used for deployment:

```
deployFactory(
0xc00e94cb662c3520282e6f5717214004a7f26888, // (Address of COMP)
0xdac17f958d2ee523a2206206994597c13d831ec7, // (Using USDT to represent USD and acquire 6 decimals)
0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5, // a valid COMP/USD Price Feed
0xD72ac1bCE9177CFe7aEb5d0516a38c88a64cE0AB, // constant price feed to return 1 USD
<RETURN_ADDRESS>,
<RECIPIENT_ADDRESS>,
1000000000000, // $1M with 6 decimals (Minimal required decimals)
<SLIPPAGE>,
<CLAIM_COOLDOWN>,
<SWEEP_COOLDOWN>,
31536000, // seconds in 365 days, representing stream duration
<MINIMUM_NOTICE_PERIOD>
)
```

After the initialization, the recipient will be able to claim 1000000 / $40 / 365 = 65,5 COMP per day. (Provided that the price doesn't change).

##### Example 3. Distribute 1M worth of USDC in WETH

There is a need to distribute 1M worth of USDC in WETH. Assuming that the price of WETH is $2500 and 1 USDC = 1 USD:

```
deployFactory(
0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, // Address of Wrapped ETH
0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, // Address of USDC
0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // a valid ETH/USD Price Feed
0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6, // a valid USDC/USD Price Feed
<RETURN_ADDRESS>,
<RECIPIENT_ADDRESS>,
1000000000000, // $1M with 6 decimals (USDC has 6 decimals)
<SLIPPAGE>,
<CLAIM_COOLDOWN>,
<SWEEP_COOLDOWN>,
31536000, // seconds in 365 days, representing stream duration
<MINIMUM_NOTICE_PERIOD>
)
```

After the initialization, the recipient will be able to claim 1000000 / $2500 / 365 = 1,09 WETH per day. (Provided that the price doesn't change).

## Streamer lifecycle

The process of asset streaming

##### Deployment

The deployment is performed via `deployStreamer` function of StreamerFactory. Make sure to prepare all the necessary parameters which include:

- `_streamingAsset` and `_nativeAsset`. Make sure that these are valid ERC-20 tokens.
- `_streamingAssetOracle` and `_nativeAssetOracle`. Streamer is designed to work with the Chainlink Price Feeds which return price in USD, however, can work with any oracles which support AggregatorV3Interface and return the price in USD.
- `_returnAddress`, `_recipient`. Ensure that these are valid addresses which are entitled to receive ERC-20 tokens. `_recipient` should be able to call the function `claim()` of the Streamer.
- `_nativeAssetStreamingAmount`. An amount of Native asset to be streamed. This value should have number of decimals equal to the number of decimals in Native Asset.
- `_slippage`. A slippage parameter used to reduce the price of the streaming asset. For example, to set slippage to 0.5% use 5e5.
- `_claimCooldown`, `_sweepCooldown`, `_streamDuration`, `_minimumNoticePeriod`. Set cooldown periods in seconds. Minimal period is 1 day. `_minimumNoticePeriod` must be shorter that `_streamDuration`.
  **Note!** For more details about parameter check the documentation of Streamer.

> Call the function `deployStreamer` with the necessary parameters of a new Streamer.

##### Initialization

In order to start the stream, the function `initialize` must be called by Stream Creator.
Before calling this function, The Streamer smart contract should have enough Streaming asset tokens on its balance. You can calculate the necessary amount of Streaming asset using the function `calculateStreamingAssetAmount()`.
**Note!** due to the price fluctuations between assets, we recommend transferring extra amount of streaming asset, for example, extra 10%.

> The Stream Creator should call the function `initialize`.

##### Main flow of the Streamer. Claim, terminate, sweep.

**Claim process**
The recipient is able to claim Streaming asset during the streaming period or claim all after the end of stream. Streaming asset is allocated linerly each second.
Additionally, the `claim()` function can be called by anyone after the `claimingPeriod` has passed since the last claiming. This is implemented to ensure that the recipient won't wait too long for a more favorable price of assets.

> Recipient is able to call function `claim()` during the stream period and after the stream end to claim allocated Streaming asset tokens.

**Termination process**
Stream creator is able to stop the stream at any time while the stream is active using the function `terminateStream()`. Termination of the stream means the the allocation will be fully stopped after the `terminationTimestamp`. The stream will continue to accrue tokens for a certain period of time (notice period), which lasts till the `terminationTimestamp`. The function accept parameter `_terminationTimestamp`. This parameter should be equal the timestamp upon which the distribution of asset will be stopped. Also, it can be passed as 0, in which case the terminationTimestamp will be calculated inside the function. See description of `terminateStream()` for more details.

> Stream creator is able to call function `terminateStream()` to stop distribution of Streaming asset. This process is irreversible. Stream can be terminated only once.

**Sweep Process**
Streaming asset tokens can be swept from the Streamer's balance using the function `sweepRemaining()`.

- Before initialization of the stream, Stream Creator can call the function without any conditions.
- After initialization, Stream Creator can call the function only after the end of stream (or after termination timestamp if stream is terminated).
- Anyone can call the function after `sweepCooldown`.
  > `sweepRemaining() can be called in order to sweep remaining balance of Streaming asset provided the mentioned conditions are met.`

##### Rescuing of stuck tokens

> Stream Creator is able to call function `rescueToken()` on order to withdraw any ERC-20 token from the Streamer's balance except Streaming asset.
