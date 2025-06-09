pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";
import { Streamer } from "../Streamer.sol";
import { StreamerFactory } from "../StreamerFactory.sol";
import { SimplePriceFeed } from "../mocks/SimplePriceFeed.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { AggregatorV3Interface } from "../interfaces/AggregatorV3Interface.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { console } from "forge-std/console.sol";

contract StreamerTest is Test {
    using SignedMath for int256;

    uint256 constant slippage = 5e5;
    uint256 constant MIN_DURATION = 86400 * 5;
    uint256 constant MAX_DURATION = 86400 * 365 * 5;

    StreamerFactory factory;
    Streamer streamer;
    MockERC20 streamingToken;
    MockERC20 nativeToken;
    SimplePriceFeed streamingAssetPriceFeed;
    SimplePriceFeed nativeAssetPriceFeed;

    address recipient;
    address returnAddress;
    address streamCreator;

    function setUp() public {
        factory = new StreamerFactory();
        recipient = makeAddr("recipient");
        returnAddress = makeAddr("returnAddress");
        streamCreator = makeAddr("streamCreator");
    }

    function _deployTokens(uint8 streamingTokenDecimals, uint8 nativeTokenDecimals) internal {
        streamingToken = new MockERC20("Streaming Token", "STRTKN", streamingTokenDecimals);
        nativeToken = new MockERC20("Native Token", "NATTKN", nativeTokenDecimals);
    }

    function _deployPriceFeeds(
        uint8 streamingTokenOracleDecimals,
        uint8 nativeTokenOracleDecimals,
        uint256 streamingAssetPrice,
        uint256 nativeAssetPrice
    ) internal {
        streamingAssetPriceFeed = new SimplePriceFeed(int256(streamingAssetPrice), streamingTokenOracleDecimals);
        nativeAssetPriceFeed = new SimplePriceFeed(int256(nativeAssetPrice), nativeTokenOracleDecimals);
    }

    function _deployStreamer(
        uint256 _streamingAmount,
        uint256 _claimCooldown,
        uint256 _sweepCooldown,
        uint256 _streamDuration,
        uint256 _minimumNoticePeriod
    ) internal {
        vm.prank(streamCreator);
        streamer = Streamer(
            factory.deployStreamer(
                address(streamingToken),
                address(nativeToken),
                AggregatorV3Interface(address(streamingAssetPriceFeed)),
                AggregatorV3Interface(address(nativeAssetPriceFeed)),
                returnAddress,
                recipient,
                _streamingAmount,
                slippage,
                _claimCooldown,
                _sweepCooldown,
                _streamDuration,
                _minimumNoticePeriod
            )
        );
    }

    function _initializeStreamer(uint256 _nativeAssetAmount) internal {
        uint256 streamingAssetAmount = streamer.calculateStreamingAssetAmount(
            _nativeAssetAmount + 1 * 10 ** uint256(nativeToken.decimals())
        );
        console.log("Streaming asset minted: ", streamingAssetAmount);
        streamingToken.mint(address(streamer), streamingAssetAmount);
        vm.prank(streamCreator);
        streamer.initialize();
    }

    function _testFuzz_claim_PrepareParamsAndStreamer(
        uint256 streamingAmount,
        uint8 streamingTokenDecimals,
        uint8 nativeTokenDecimals,
        uint8 streamingTokenOracleDecimals,
        uint8 nativeTokenOracleDecimals,
        uint256 claimCooldown,
        uint256 sweepCooldown,
        uint256 streamDuration,
        uint256 streamingAssetPrice,
        uint256 nativeAssetPrice
    ) internal returns (uint256, uint8, uint8, uint8, uint8, uint256, uint256, uint256, uint256, uint256) {
        streamingTokenDecimals = uint8(bound(streamingTokenDecimals, 6, 30));
        nativeTokenDecimals = uint8(bound(nativeTokenDecimals, 6, 30));
        streamingTokenOracleDecimals = uint8(bound(streamingTokenOracleDecimals, 6, 30));
        nativeTokenOracleDecimals = uint8(bound(nativeTokenOracleDecimals, 6, 30));
        streamingAmount = bound(
            streamingAmount,
            10 ** uint256(nativeTokenDecimals - 1),
            10 ** uint256(nativeTokenDecimals)
        );
        uint256 minimumNoticePeriod = 30 days;
        streamDuration = bound(streamDuration, minimumNoticePeriod + 1, MAX_DURATION);
        claimCooldown = bound(claimCooldown, MIN_DURATION + 1, streamDuration - 1);
        sweepCooldown = bound(sweepCooldown, MIN_DURATION + 1, MAX_DURATION);
        streamingAssetPrice = bound(streamingAssetPrice, 1, 100000);
        nativeAssetPrice = bound(nativeAssetPrice, 1, 100000);
        streamingAssetPrice = streamingAssetPrice * 10 ** streamingTokenOracleDecimals;
        nativeAssetPrice = nativeAssetPrice * 10 ** nativeTokenOracleDecimals;
        vm.assume(
            (streamingAmount * nativeAssetPrice) / 10 ** nativeTokenOracleDecimals >= 1 * 10 ** nativeTokenDecimals
        ); // Assume that the initial value of streamed asset is at least 1 dollar

        _deployTokens(streamingTokenDecimals, nativeTokenDecimals);
        _deployPriceFeeds(
            streamingTokenOracleDecimals,
            nativeTokenOracleDecimals,
            streamingAssetPrice,
            nativeAssetPrice
        );
        _deployStreamer(streamingAmount, claimCooldown, sweepCooldown, streamDuration, minimumNoticePeriod);
        _initializeStreamer(streamingAmount);

        return (
            streamingAmount,
            streamingTokenDecimals,
            nativeTokenDecimals,
            streamingTokenOracleDecimals,
            nativeTokenOracleDecimals,
            claimCooldown,
            sweepCooldown,
            streamDuration,
            streamingAssetPrice,
            nativeAssetPrice
        );
    }

    function testFuzz_claim(
        uint256 streamingAmount,
        uint8 streamingTokenDecimals,
        uint8 nativeTokenDecimals,
        uint8 streamingTokenOracleDecimals,
        uint8 nativeTokenOracleDecimals,
        uint256 claimCooldown,
        uint256 sweepCooldown,
        uint256 streamDuration,
        uint256 streamingAssetPrice,
        uint256 nativeAssetPrice
    ) public {
        (
            streamingAmount,
            streamingTokenDecimals,
            nativeTokenDecimals,
            streamingTokenOracleDecimals,
            nativeTokenOracleDecimals,
            claimCooldown,
            sweepCooldown,
            streamDuration,
            streamingAssetPrice,
            nativeAssetPrice
        ) = _testFuzz_claim_PrepareParamsAndStreamer(
                streamingAmount,
                streamingTokenDecimals,
                nativeTokenDecimals,
                streamingTokenOracleDecimals,
                nativeTokenOracleDecimals,
                claimCooldown,
                sweepCooldown,
                streamDuration,
                streamingAssetPrice,
                nativeAssetPrice
            );

        vm.warp(block.timestamp + (streamDuration / 2));
        uint256 expectedAmount = streamer.calculateStreamingAssetAmount(streamer.getNativeAssetAmountOwed());
        vm.prank(recipient);
        streamer.claim();
        assertEq(expectedAmount, streamingToken.balanceOf(recipient));
    }

    function testFuzz_claimAfterStreamEnd(
        uint256 streamingAmount,
        uint8 streamingTokenDecimals,
        uint8 nativeTokenDecimals,
        uint8 streamingTokenOracleDecimals,
        uint8 nativeTokenOracleDecimals,
        uint256 claimCooldown,
        uint256 sweepCooldown,
        uint256 streamDuration,
        uint256 streamingAssetPrice,
        uint256 nativeAssetPrice
    ) public {
        (
            streamingAmount,
            streamingTokenDecimals,
            nativeTokenDecimals,
            streamingTokenOracleDecimals,
            nativeTokenOracleDecimals,
            claimCooldown,
            sweepCooldown,
            streamDuration,
            streamingAssetPrice,
            nativeAssetPrice
        ) = _testFuzz_claim_PrepareParamsAndStreamer(
                streamingAmount,
                streamingTokenDecimals,
                nativeTokenDecimals,
                streamingTokenOracleDecimals,
                nativeTokenOracleDecimals,
                claimCooldown,
                sweepCooldown,
                streamDuration,
                streamingAssetPrice,
                nativeAssetPrice
            );

        uint256 expectedAmount = streamer.calculateStreamingAssetAmount(streamingAmount);
        vm.warp(block.timestamp + streamDuration);
        vm.prank(recipient);
        streamer.claim();
        assertEq(expectedAmount, streamingToken.balanceOf(recipient));
    }

    function testFuzz_assetPriceChange(
        uint256 streamingAmount,
        uint8 streamingTokenDecimals,
        uint8 nativeTokenDecimals,
        uint8 streamingTokenOracleDecimals,
        uint8 nativeTokenOracleDecimals,
        uint256 claimCooldown,
        uint256 sweepCooldown,
        uint256 streamDuration,
        uint256 streamingAssetPrice,
        uint256 nativeAssetPrice,
        int256[10] memory streamingAssetPriceChangePercent,
        int256[10] memory nativeAssetPriceChangePercent
    ) public {
        (
            streamingAmount,
            streamingTokenDecimals,
            nativeTokenDecimals,
            streamingTokenOracleDecimals,
            nativeTokenOracleDecimals,
            claimCooldown,
            sweepCooldown,
            streamDuration,
            streamingAssetPrice,
            nativeAssetPrice
        ) = _testFuzz_claim_PrepareParamsAndStreamer(
                streamingAmount,
                streamingTokenDecimals,
                nativeTokenDecimals,
                streamingTokenOracleDecimals,
                nativeTokenOracleDecimals,
                claimCooldown,
                sweepCooldown,
                streamDuration,
                streamingAssetPrice,
                nativeAssetPrice
            );

        for (uint256 i = 0; i < streamingAssetPriceChangePercent.length; i++) {
            streamingAssetPriceChangePercent[i] = bound(streamingAssetPriceChangePercent[i], -20, 20); // Allow price change from 1 to 20%
            vm.assume(streamingAssetPriceChangePercent[i] != 0);
            nativeAssetPriceChangePercent[i] = bound(nativeAssetPriceChangePercent[i], -20, 20); // Allow price change from 1 to 20%
            vm.assume(nativeAssetPriceChangePercent[i] != 0);
        }

        // Mint additional streaming asset tokens to support the price changes
        streamingToken.mint(address(streamer), streamingToken.balanceOf(address(streamer)) * 10000);

        vm.startPrank(recipient);
        for (uint256 i = 0; i < streamingAssetPriceChangePercent.length; i++) {
            // Change price of assets
            uint256 streamingAssetDeltaPrice = (streamingAssetPrice * streamingAssetPriceChangePercent[i].abs()) / 100;
            uint256 nativeAssetDeltaPrice = (nativeAssetPrice * nativeAssetPriceChangePercent[i].abs()) / 100;
            streamingAssetPrice = streamingAssetPriceChangePercent[i] < 0
                ? streamingAssetPrice - streamingAssetDeltaPrice
                : streamingAssetPrice + streamingAssetDeltaPrice;
            nativeAssetPrice = nativeAssetPriceChangePercent[i] < 0
                ? nativeAssetPrice - nativeAssetDeltaPrice
                : nativeAssetPrice + nativeAssetDeltaPrice;
            streamingAssetPriceFeed.setPrice(int256(streamingAssetPrice));
            nativeAssetPriceFeed.setPrice(int256(nativeAssetPrice));

            vm.warp(block.timestamp + (streamDuration / streamingAssetPriceChangePercent.length));

            uint256 expectedAmount = streamer.calculateStreamingAssetAmount(streamer.getNativeAssetAmountOwed());
            uint256 balBefore = streamingToken.balanceOf(recipient);
            streamer.claim();
            assertEq(expectedAmount, streamingToken.balanceOf(recipient) - balBefore);
        }
        vm.stopPrank();
    }
}
