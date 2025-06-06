# Solidity API

## StreamerFactory

### deployStreamer

```solidity
function deployStreamer(address _streamingAsset, address _nativeAsset, contract AggregatorV3Interface _streamingAssetOracle, contract AggregatorV3Interface _nativeAssetOracle, address _returnAddress, address _recipient, uint256 _streamingAmount, uint256 _slippage, uint256 _claimCooldown, uint256 _sweepCooldown, uint256 _streamDuration, bytes32 salt) external returns (address)
```

