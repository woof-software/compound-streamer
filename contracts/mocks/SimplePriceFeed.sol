// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import "../interfaces/AggregatorV3Interface.sol";

contract SimplePriceFeed is AggregatorV3Interface {
    string public constant override description = "Mock Chainlink price aggregator";

    uint public constant override version = 1;

    uint8 public immutable override decimals;

    uint80 internal roundId;
    int256 internal answer;
    uint256 internal startedAt;
    uint256 internal updatedAt;
    uint80 internal answeredInRound;

    constructor(int answer_, uint8 decimals_) {
        answer = answer_;
        decimals = decimals_;
    }

    function setPrice(int256 answer_) public {
        answer = answer_;
    }

    function setRoundData(
        uint80 roundId_,
        int256 answer_,
        uint256 startedAt_,
        uint256 updatedAt_,
        uint80 answeredInRound_
    ) public {
        roundId = roundId_;
        answer = answer_;
        startedAt = startedAt_;
        updatedAt = updatedAt_;
        answeredInRound = answeredInRound_;
    }

    function getRoundData(uint80 roundId_) external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId_, answer, startedAt, updatedAt, answeredInRound);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
