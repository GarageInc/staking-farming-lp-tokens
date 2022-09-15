// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IMasterChef {
    function mint(uint256 _amount) external;

    function redeemUnderlying(uint256 _amount) external;

    function underlying() external view returns (address);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}
