// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IComptrollerV2 {
    function _grantComp(address recipient, uint256 amount) external;
}
