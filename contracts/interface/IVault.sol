// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IVault {
    function decimals() external view returns (uint8);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);
}
