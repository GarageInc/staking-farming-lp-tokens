// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IMasterChef {
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 boostMultiplier
        );

    function lpToken(uint256 _pid) external view returns (address lpToken);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256 _amount);
}
