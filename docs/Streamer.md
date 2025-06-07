# Solidity API

## Streamer

### SLIPPAGE_SCALE

```solidity
uint256 SLIPPAGE_SCALE
```

### MIN_DURATION

```solidity
uint256 MIN_DURATION
```

### streamingAsset

```solidity
contract IERC20 streamingAsset
```

### streamingAssetOracle

```solidity
contract AggregatorV3Interface streamingAssetOracle
```

### nativeAssetOracle

```solidity
contract AggregatorV3Interface nativeAssetOracle
```

### returnAddress

```solidity
address returnAddress
```

### streamCreator

```solidity
address streamCreator
```

### recipient

```solidity
address recipient
```

### streamingAmount

```solidity
uint256 streamingAmount
```

### slippage

```solidity
uint256 slippage
```

### claimCooldown

```solidity
uint256 claimCooldown
```

### sweepCooldown

```solidity
uint256 sweepCooldown
```

### streamDuration

```solidity
uint256 streamDuration
```

### minimumNoticePeriod

```solidity
uint256 minimumNoticePeriod
```

### streamingAssetDecimals

```solidity
uint8 streamingAssetDecimals
```

### nativeAssetDecimals

```solidity
uint8 nativeAssetDecimals
```

### streamingAssetOracleDecimals

```solidity
uint8 streamingAssetOracleDecimals
```

### nativeAssetOracleDecimals

```solidity
uint8 nativeAssetOracleDecimals
```

### startTimestamp

```solidity
uint256 startTimestamp
```

### lastClaimTimestamp

```solidity
uint256 lastClaimTimestamp
```

### terminationTimestamp

```solidity
uint256 terminationTimestamp
```

### nativeAssetSuppliedAmount

```solidity
uint256 nativeAssetSuppliedAmount
```

### streamingAssetClaimedAmount

```solidity
uint256 streamingAssetClaimedAmount
```

### state

```solidity
enum StreamState state
```

### onlyStreamCreator

```solidity
modifier onlyStreamCreator()
```

### constructor

```solidity
constructor(contract IERC20 _streamingAsset, contract AggregatorV3Interface _streamingAssetOracle, contract AggregatorV3Interface _nativeAssetOracle, address _returnAddress, address _streamCreator, address _recipient, uint8 _streamingAssetDecimals, uint8 _nativeAssetDecimals, uint256 _streamingAmount, uint256 _slippage, uint256 _claimCooldown, uint256 _sweepCooldown, uint256 _streamDuration, uint256 _minimumNoticePeriod) public
```

### initialize

```solidity
function initialize() external
```

### claim

```solidity
function claim() external
```

### terminateStream

```solidity
function terminateStream(uint256 _terminationTimestamp) external
```

### sweepRemaining

```solidity
function sweepRemaining() external
```

### rescueToken

```solidity
function rescueToken(contract IERC20 token) external
```

### getNativeAssetAmountOwed

```solidity
function getNativeAssetAmountOwed() public view returns (uint256)
```

### calculateStreamingAssetAmount

```solidity
function calculateStreamingAssetAmount(uint256 nativeAssetAmount) public view returns (uint256)
```

### calculateNativeAssetAmount

```solidity
function calculateNativeAssetAmount(uint256 streamingAssetAmount) public view returns (uint256)
```

### scaleAmount

```solidity
function scaleAmount(uint256 amount, uint256 fromDecimals, uint256 toDecimals) internal pure returns (uint256)
```

Scales an amount from one decimal representation to another

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to be scaled |
| fromDecimals | uint256 | The number of decimals of the original amount |
| toDecimals | uint256 | The number of decimals of the target amount |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The scaled amount |

