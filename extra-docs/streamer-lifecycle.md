# Streamer lifecycle

## The process of asset streaming

### Deployment

The deployment is performed via `deployStreamer` function of StreamerFactory. Make sure to prepare all the necessary parameters which include:

- `_streamingAsset` and `_nativeAsset`. Make sure that these are valid ERC-20 tokens.
- `_streamingAssetOracle` and `_nativeAssetOracle`. Streamer is designed to work with the Chainlink Price Feeds which return price in USD, however, can work with any oracles which support AggregatorV3Interface and return the price in USD.
- `_returnAddress`, `_recipient`. Ensure that these are valid addresses which are entitled to receive ERC-20 tokens. `_recipient` should be able to call the function `claim()` of the Streamer.
- `_nativeAssetStreamingAmount`. An amount of Native asset to be streamed. This value should have number of decimals equal to the number of decimals in Native Asset.
- `_slippage`. A slippage parameter used to reduce the price of the streaming asset. For example, to set slippage to 0.5% use 5e5.
- `_claimCooldown`, `_sweepCooldown`, `_streamDuration`, `_minimumNoticePeriod`. Set cooldown periods in seconds. Minimal period is 1 day. `_minimumNoticePeriod` must be shorter that `_streamDuration`.
  **Note!** For more details about parameter check the documentation of Streamer.
  > Call the function `deployStreamer` with the necessary parameters of a new Streamer.

### Initialization

In order to start the stream, the function `initialize` must be called by Stream Creator.
Before calling this function, The Streamer smart contract should have enough Streaming asset tokens on its balance. You can calculate the necessary amount of Streaming asset using the function `calculateStreamingAssetAmount()`.
**Note!** due to the price fluctuations between assets, we recommend transferring extra amount of streaming asset, for example, extra 10%.

> The Stream Creator should call the function `initialize`.

### Main flow of the Streamer. Claim, terminate, sweep.

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

### Rescuing of stuck tokens

> Stream Creator is able to call function `rescueToken()` on order to withdraw any ERC-20 token from the Streamer's balance except Streaming asset.
