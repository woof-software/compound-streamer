# Solidity API

## StreamState

```solidity
enum StreamState {
  NOT_INITIALIZED,
  ONGOING,
  FINISHED,
  NOTICE_PERIOD,
  CANCELED
}
```

## IStreamer

### Claimed

```solidity
event Claimed(uint256 compAmount, uint256 usdcAmount)
```

### Swept

```solidity
event Swept(uint256 amount)
```

### Initialized

```solidity
event Initialized()
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### NotReceiver

```solidity
error NotReceiver()
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### SlippageExceedsScaleFactor

```solidity
error SlippageExceedsScaleFactor()
```

### InvalidPrice

```solidity
error InvalidPrice()
```

### OnlyStreamCreator

```solidity
error OnlyStreamCreator()
```

### NotInitialized

```solidity
error NotInitialized()
```

### NotEnoughBalance

```solidity
error NotEnoughBalance(uint256 balance, uint256 streamingAmount)
```

### StreamNotFinished

```solidity
error StreamNotFinished()
```

### AlreadyInitialized

```solidity
error AlreadyInitialized()
```

### DurationTooShort

```solidity
error DurationTooShort()
```

### initialize

```solidity
function initialize() external
```

### claim

```solidity
function claim() external
```

### sweepRemaining

```solidity
function sweepRemaining() external
```

### getNativeAssetAmountOwed

```solidity
function getNativeAssetAmountOwed() external view returns (uint256)
```

### calculateStreamingAssetAmount

```solidity
function calculateStreamingAssetAmount(uint256 nativeAssetAmount) external view returns (uint256)
```

### calculateNativeAssetAmount

```solidity
function calculateNativeAssetAmount(uint256 streamingAssetAmount) external view returns (uint256)
```

