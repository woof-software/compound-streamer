// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { StreamState, IStreamer } from "./interfaces/IStreamer.sol";

contract Streamer is IStreamer {
    using SafeERC20 for IERC20;

    uint256 public constant SLIPPAGE_SCALE = 1e8;
    uint256 public constant MIN_DURATION = 1 days;

    IERC20 public immutable streamingAsset;
    AggregatorV3Interface public immutable streamingAssetOracle;
    AggregatorV3Interface public immutable nativeAssetOracle;
    address public immutable returnAddress;
    address public immutable streamCreator;
    address public immutable recipient;
    uint256 public immutable streamingAmount;
    uint256 public immutable slippage;
    uint256 public immutable claimCooldown;
    uint256 public immutable sweepCooldown;
    uint256 public immutable streamDuration;
    uint256 public immutable minimumNoticePeriod;
    uint8 public immutable streamingAssetDecimals;
    uint8 public immutable nativeAssetDecimals;
    uint8 public immutable streamingAssetOracleDecimals;
    uint8 public immutable nativeAssetOracleDecimals;
    uint256 public startTimestamp;
    uint256 public lastClaimTimestamp;
    uint256 public terminationTimestamp;
    uint256 public nativeAssetSuppliedAmount;
    uint256 public streamingAssetClaimedAmount;
    StreamState public state;

    modifier onlyStreamCreator() {
        if (msg.sender != streamCreator) revert NotStreamCreator();
        _;
    }

    constructor(
        IERC20 _streamingAsset,
        AggregatorV3Interface _streamingAssetOracle,
        AggregatorV3Interface _nativeAssetOracle,
        address _returnAddress,
        address _streamCreator,
        address _recipient,
        uint8 _streamingAssetDecimals,
        uint8 _nativeAssetDecimals,
        uint256 _streamingAmount,
        uint256 _slippage,
        uint256 _claimCooldown,
        uint256 _sweepCooldown,
        uint256 _streamDuration,
        uint256 _minimumNoticePeriod
    ) {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_streamCreator == address(0)) revert ZeroAddress();
        if (_returnAddress == address(0)) revert ZeroAddress();
        if (address(_streamingAsset) == address(0)) revert ZeroAddress();
        if (_streamingAmount == 0) revert ZeroAmount();
        if (_slippage > SLIPPAGE_SCALE) revert SlippageExceedsScaleFactor();
        if (_claimCooldown < MIN_DURATION) revert DurationTooShort();
        if (_sweepCooldown < MIN_DURATION) revert DurationTooShort();
        if (_streamDuration < MIN_DURATION) revert DurationTooShort();
        if (_minimumNoticePeriod < MIN_DURATION) revert DurationTooShort();
        if (_minimumNoticePeriod > _streamDuration) revert NoticePeriodExceedsStreamDuration();
        streamingAssetOracleDecimals = AggregatorV3Interface(_streamingAssetOracle).decimals();
        nativeAssetOracleDecimals = AggregatorV3Interface(_nativeAssetOracle).decimals();
        streamingAsset = _streamingAsset;
        streamingAssetOracle = _streamingAssetOracle;
        nativeAssetOracle = _nativeAssetOracle;
        returnAddress = _returnAddress;
        streamCreator = _streamCreator;
        recipient = _recipient;
        streamingAssetDecimals = _streamingAssetDecimals;
        nativeAssetDecimals = _nativeAssetDecimals;
        streamingAmount = _streamingAmount;
        slippage = _slippage;
        claimCooldown = _claimCooldown;
        sweepCooldown = _sweepCooldown;
        streamDuration = _streamDuration;
        minimumNoticePeriod = _minimumNoticePeriod;
    }

    function initialize() external {
        if (state != StreamState.NOT_INITIALIZED) revert AlreadyInitialized();
        if (msg.sender != streamCreator) revert NotStreamCreator();
        startTimestamp = block.timestamp;
        lastClaimTimestamp = block.timestamp;
        state = StreamState.ONGOING;

        // expect that comp balance is enough to cover the stream amount
        uint256 balance = streamingAsset.balanceOf(address(this));
        if (calculateNativeAssetAmount(balance) < streamingAmount) revert NotEnoughBalance(balance, streamingAmount);

        emit Initialized();
    }

    function claim() external {
        if (state == StreamState.NOT_INITIALIZED) revert NotInitialized();
        // Check if the caller is the receiver
        // and allow anyone to claim if the last claim was more than claim cooldown
        if (msg.sender != recipient && block.timestamp < lastClaimTimestamp + claimCooldown) revert NotReceiver();

        uint256 owed = getNativeAssetAmountOwed();
        if (owed == 0) revert ZeroAmount();

        uint256 streamingAssetAmount = calculateStreamingAssetAmount(owed);
        if (streamingAssetAmount == 0) revert ZeroAmount();

        uint256 balance = streamingAsset.balanceOf(address(this));
        if (balance < streamingAssetAmount) {
            streamingAssetAmount = balance;
            owed = calculateNativeAssetAmount(balance);
        }

        lastClaimTimestamp = block.timestamp;
        nativeAssetSuppliedAmount += owed;
        streamingAssetClaimedAmount += streamingAssetAmount;

        streamingAsset.safeTransfer(recipient, streamingAssetAmount);
        emit Claimed(streamingAssetAmount, owed);
    }

    function terminateStream(uint256 _terminationTimestamp) external onlyStreamCreator {
        if (state == StreamState.TERMINATED) revert AlreadyTerminated();
        if (_terminationTimestamp == 0) {
            terminationTimestamp = block.timestamp + minimumNoticePeriod;
        } else {
            if (_terminationTimestamp < block.timestamp + minimumNoticePeriod) revert DurationTooShort();
            terminationTimestamp = _terminationTimestamp;
        }

        if (terminationTimestamp > startTimestamp + streamDuration)
            revert TerminationIsAfterStream(_terminationTimestamp);
        state = StreamState.TERMINATED;
        emit Terminated(terminationTimestamp);
    }

    function sweepRemaining() external {
        if (state == StreamState.NOT_INITIALIZED) {
            if (msg.sender != streamCreator) {
                revert NotStreamCreator();
            }
        } else {
            uint256 streamEnd = (state == StreamState.TERMINATED)
                ? terminationTimestamp
                : startTimestamp + streamDuration;

            if (msg.sender == streamCreator) {
                if (block.timestamp <= streamEnd) {
                    revert CreatorCannotSweepYet();
                }
            } else if (block.timestamp <= streamEnd + sweepCooldown) {
                revert SweepCooldownNotPassed();
            }
        }
        uint256 remainingBalance = streamingAsset.balanceOf(address(this));

        streamingAsset.safeTransfer(returnAddress, remainingBalance);
        emit Swept(remainingBalance);
    }

    function rescueToken(IERC20 token) external onlyStreamCreator {
        if (token == streamingAsset) revert CantRescueStreamingAsset();
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(returnAddress, balance);
        emit Rescued(address(token), balance);
    }

    function getNativeAssetAmountOwed() public view returns (uint256) {
        if (nativeAssetSuppliedAmount >= streamingAmount) {
            return 0;
        }
        uint256 streamEnd = state == StreamState.TERMINATED ? terminationTimestamp : startTimestamp + streamDuration;
        uint256 totalOwed;

        if (block.timestamp < streamEnd) {
            uint256 elapsed = block.timestamp - startTimestamp;
            totalOwed = (streamingAmount * elapsed) / streamDuration;
        } else {
            // If Stream is terminated, calculate amount accrued before termination timestamp
            if (state == StreamState.TERMINATED)
                totalOwed = (streamingAmount * (streamEnd - startTimestamp)) / streamDuration;
            else totalOwed = streamingAmount;
        }
        return totalOwed - nativeAssetSuppliedAmount;
    }

    function calculateStreamingAssetAmount(uint256 nativeAssetAmount) public view returns (uint256) {
        (, int256 streamingAssetPrice, , , ) = AggregatorV3Interface(streamingAssetOracle).latestRoundData();
        if (streamingAssetPrice <= 0) revert InvalidPrice();

        (, int256 nativeAssetPrice, , , ) = AggregatorV3Interface(nativeAssetOracle).latestRoundData();
        if (nativeAssetPrice <= 0) revert InvalidPrice();

        // Streaming asset price is reduced by slippage to account for price fluctuations
        uint256 streamingAssetPriceScaled = (scaleAmount(
            uint256(streamingAssetPrice),
            streamingAssetOracleDecimals,
            streamingAssetDecimals
        ) * (SLIPPAGE_SCALE - slippage)) / SLIPPAGE_SCALE;
        // Scale native asset price to streaming asset decimals for calculations
        uint256 nativeAssetPriceScaled = scaleAmount(
            uint256(nativeAssetPrice),
            nativeAssetOracleDecimals,
            streamingAssetDecimals
        );

        uint256 nativeAssetAmountInUSD = (scaleAmount(nativeAssetAmount, nativeAssetDecimals, streamingAssetDecimals) *
            nativeAssetPriceScaled) / 10 ** streamingAssetDecimals;
        uint256 amountinStreamingAsset = (nativeAssetAmountInUSD * 10 ** streamingAssetDecimals) /
            streamingAssetPriceScaled;
        return amountinStreamingAsset;
    }

    function calculateNativeAssetAmount(uint256 streamingAssetAmount) public view returns (uint256) {
        (, int256 streamingAssetPrice, , , ) = AggregatorV3Interface(streamingAssetOracle).latestRoundData();
        if (streamingAssetPrice <= 0) revert InvalidPrice();

        (, int256 nativeAssetPrice, , , ) = AggregatorV3Interface(nativeAssetOracle).latestRoundData();
        if (nativeAssetPrice <= 0) revert InvalidPrice();

        // Streaming asset price is reduced by slippage to account for price fluctuations
        uint256 streamingAssetPriceScaled = (scaleAmount(
            uint256(streamingAssetPrice),
            streamingAssetOracleDecimals,
            streamingAssetDecimals
        ) * (SLIPPAGE_SCALE - slippage)) / SLIPPAGE_SCALE;
        // Scale native asset price to streaming asset decimals for calculations
        uint256 nativeAssetPriceScaled = scaleAmount(
            uint256(nativeAssetPrice),
            nativeAssetOracleDecimals,
            streamingAssetDecimals
        );

        uint256 streamingAssetAmountInUSD = (streamingAssetAmount * streamingAssetPriceScaled) /
            10 ** streamingAssetDecimals;
        uint256 amountInNativeAsset = (streamingAssetAmountInUSD * 10 ** nativeAssetDecimals) / nativeAssetPriceScaled;
        return amountInNativeAsset;
    }

    /// @notice Scales an amount from one decimal representation to another
    /// @param amount The amount to be scaled
    /// @param fromDecimals The number of decimals of the original amount
    /// @param toDecimals The number of decimals of the target amount
    /// @return The scaled amount
    function scaleAmount(uint256 amount, uint256 fromDecimals, uint256 toDecimals) internal pure returns (uint256) {
        if (fromDecimals > toDecimals) {
            return amount / (10 ** (fromDecimals - toDecimals));
        } else {
            return amount * (10 ** (toDecimals - fromDecimals));
        }
    }
}
