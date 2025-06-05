// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

enum StreamState {
    NOT_INITIALIZED,
    ONGOING,
    FINISHED,
    NOTICE_PERIOD,
    CANCELED
}

interface IStreamer {
    event Claimed(uint256 compAmount, uint256 usdcAmount);
    event Swept(uint256 amount);
    event Initialized();

    error ZeroAmount();
    error NotReceiver();
    error ZeroAddress();
    error SlippageExceedsScaleFactor();
    error InvalidPrice();
    error OnlyStreamCreator();
    error NotInitialized();
    error NotEnoughBalance();
    error StreamNotFinished();
    error AlreadyInitialized();
    error DurationTooShort();

    function initialize() external;

    function claim() external;

    function sweepRemaining() external;

    function getNativeAssetAmountOwed() external view returns (uint256);

    function calculateStreamingAssetAmount(uint256 nativeAssetAmount) external view returns (uint256);

    function calculateNativeAssetAmount(uint256 streamingAssetAmount) external view returns (uint256);
}
