// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IController {
    function claimComp(address holder) external;

    function compAccrued(address holder) external view returns (uint256);
}
