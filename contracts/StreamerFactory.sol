// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IStreamerFactory } from "./interfaces/IStreamerFactory.sol";
import { Streamer } from "./Streamer.sol";

contract StreamerFactory is IStreamerFactory {
    uint256 public counter;

    function deployStreamer(
        address _streamingAsset,
        address _nativeAsset,
        AggregatorV3Interface _streamingAssetOracle,
        AggregatorV3Interface _nativeAssetOracle,
        address _returnAddress,
        address _recipient,
        uint256 _streamingAmount,
        uint256 _slippage,
        uint256 _claimCooldown,
        uint256 _sweepCooldown,
        uint256 _streamDuration
    ) external returns (address) {
        if (_streamingAsset == _nativeAsset) revert AssetsMatch();
        uint8 streamingAssetDecimals = IERC20Metadata(_streamingAsset).decimals();
        uint8 nativeAssetDecimals = IERC20Metadata(_nativeAsset).decimals();
        bytes memory constructorParams = abi.encode(
            IERC20(_streamingAsset),
            _streamingAssetOracle,
            _nativeAssetOracle,
            _returnAddress,
            msg.sender,
            _recipient,
            streamingAssetDecimals,
            nativeAssetDecimals,
            _streamingAmount,
            _slippage,
            _claimCooldown,
            _sweepCooldown,
            _streamDuration
        );
        bytes32 uniqueSalt = keccak256(abi.encode(msg.sender, counter++, constructorParams));
        bytes memory bytecodeWithParams = abi.encodePacked(type(Streamer).creationCode, constructorParams);
        address newContract = Create2.computeAddress(uniqueSalt, keccak256(bytecodeWithParams));

        if (newContract.code.length != 0) revert ContractIsAlreadyDeployedException(newContract);
        Create2.deploy(0, uniqueSalt, bytecodeWithParams);

        emit StreamerDeployed(newContract, constructorParams);
        return newContract;
    }
}
