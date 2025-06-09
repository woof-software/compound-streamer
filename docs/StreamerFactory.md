# Solidity API

## StreamerFactory

a Factory smart contract used for a safe deployment of new Streamer instances.
Anyone can use this streamer to deploy new streamers.

### counter

```solidity
uint256 counter
```

A number used to generate a unique salt for Create2.

### deployStreamer

```solidity
function deployStreamer(address _streamingAsset, address _nativeAsset, contract AggregatorV3Interface _streamingAssetOracle, contract AggregatorV3Interface _nativeAssetOracle, address _returnAddress, address _recipient, uint256 _nativeAssetStreamingAmount, uint256 _slippage, uint256 _claimCooldown, uint256 _sweepCooldown, uint256 _streamDuration, uint256 _minimumNoticePeriod) external returns (address)
```

Deploys a new Streamer instance.

_For details of each parameter, check documentation for Streamer._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of a new Streamer instance. |

