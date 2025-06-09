# Description of smart contracts

[Streamer.sol](./contracts/Streamer.sol) - The Streamer smart contract is implemented for linear streaming of a native asset's value in the form of another ERC-20 token (streaming asset) to a recipient over a specified time period. It supports `AggregatorV3Interface` to convert between the native and streaming assets based on real-time USD prices, supporting price slippage for streaming asset.
[StreamerFactory.sol](./contracts/StreamerFactory.sol) - The Streamer Factory is a smart contract that enable the deployment of new Streamer instances using Create2. The contract allows customazible parameters such as streaming and native assets, price oracles, slippage, cooldowns, and durations during each deployment of Streamer. The Factory allows users to safely and predictably deploy Streamer contracts.

Key functionalities:

    Stream creation and initialization

    Accrual and claim of streaming tokens

    Stream termination with notice period

    Rescue of non-streaming tokens

    Sweeping of unclaimed tokens before initialization and after stream ends

This contract is typically used for scheduled payments or vesting mechanisms with on-chain enforcement and real-time pricing.

### Example 1

There is a need to distribute 1 million USDC worth of Comp tokens over 1-year period. Assuming that the price of COMP is 40$ and 1 USDC = 1 USD:

- `nativeAssetStreamingAmount` - 1 million \* 10^6 (Since USDC has 6 decimals).
- Distribution period is 1 year, meaning tha approximately 2739 USDC is unlocked each day.
- Assuming that the price doesn't change, the recipient can claim 2739 / 40 = 68,475 COMP.

**Example 1.1.** 2 month has passed meaning that ~ 60 \* 2379 = 142740 USDC has unlocked. If the user claims right away, he will be able to claim 142740 / 40$ = 3568,5 Comp. The user decides to wait and the price of Comp drops and now equal to 35$. Now the user claims and receives approximately 142740 / 35$ = 4078,2 Comp.

**Example 1.2.** 5 month has passed. The Stream Creator decides to terminate the stream with a 1-month notice period. The user is still eligible to claim tokens for passed 5 month. Streaming asset continue to linearly accrue during the notice period. At the end of the Stream, the user is able to claim 6 _ 30 _ 2379 = 428220 USDC or 428220 / 40$ = 10705,5 Comp.

### Example 2

There is a need to distribute 1M worth of USD in Comp tokens. Assuming that the price of COMP is 40$:
The following parameters should be used for deployment:

- `_streamingAsset` - `0xc00e94cb662c3520282e6f5717214004a7f26888` (Address of COMP)
- `_nativeAsset` - `0xdac17f958d2ee523a2206206994597c13d831ec7` (Using USDT to represent USD and acquire 6 decimals)
- `nativeAssetStreamingAmount` - 1 million \* 10^6 (Minimal required decimals).
- `_streamingAssetOracle` - `0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5` a valid COMP/USD Price Feed
- `_nativeAssetOracle` - `0xD72ac1bCE9177CFe7aEb5d0516a38c88a64cE0AB` constant price feed to return 1 USD
- `_streamDuration` - `31536000` seconds in 365 days
  After the initialization, the recipient will be able to claim 1000000 / 40$ / 365 = 65,5 COMP per day. (Provided that the price doesn't change).

### Example 3

There is a need to distribute 1M worth of USDC in WETH. Assuming that the price of WETH is 2500$ and 1 USDC = 1 USD:

- `_streamingAsset` - `0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2` (Address of Wrapped ETH)
- `_nativeAsset` - `0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` (Address of USDC)
- `nativeAssetStreamingAmount` - 1 million \* 10^6 (Minimal required decimals).
- `_streamingAssetOracle` - `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` a valid ETH/USD Price Feed
- `_nativeAssetOracle` - `0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6` a valid USDC/USD Price Feed
- `_streamDuration` - `31536000` seconds in 365 days
  After the initialization, the recipient will be able to claim 1000000 / 2500$ / 365 = 1,09 WETH per day. (Provided that the price doesn't change).
