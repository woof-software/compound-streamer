# Streamer description

The Streamer smart contract is implemented for linear streaming of a native asset's value in the form of another ERC-20 token (streaming asset) to a recipient over a specified time period. It supports `AggregatorV3Interface` to convert between the native and streaming assets based on real-time USD prices, supporting price slippage for streaming asset.

Key functionalities:

    Stream creation and initialization

    Accrual and claim of streaming tokens

    Stream termination with notice period

    Rescue of non-streaming tokens

    Sweeping of unclaimed tokens before initialization and after stream ends

This contract is typically used for scheduled payments or vesting mechanisms with on-chain enforcement and real-time pricing.

### Example

There is a need to distribute 1 million USDC worth of Comp tokens over 1-year period. Assuming that the Comp price is 40$ and 1 USDC = 1 USD:

- `nativeAssetStreamingAmount` = 1 million \* 10^6 (Since USDC has 6 decimals).
- Distribution period is 1 year, meaning tha approximately 2739 USDC is unlocked each day.
- Assuming that the price doesn't change, the recipient can claim 2739 / 40 = 68,475 COMP.
- **Example 1.** 2 month has passed meaning that ~ 60 \* 2379 = 142740 USDC has unlocked. If the user claims right away, he will be able to claim 142740 / 40$ = 3568,5 Comp. The user decides to wait and the price of Comp drops and now equal to 35$. Now the user claims and receives approximately 142740 / 35$ = 4078,2 Comp.

  **Example 2.** 5 month has passed. The Stream Creator decides to terminate the stream with a 1-month notice period. The user is still eligible to claim tokens for passed 5 month. Streaming asset continue to linearly accrue during the notice period. At the end of the Stream, the user is able to claim 6 _ 30 _ 2379 = 428220 USDC or 428220 / 40$ = 10705,5 Comp.
