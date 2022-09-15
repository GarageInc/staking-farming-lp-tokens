// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IMasterChef {
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256 amount, uint256 rewardDept);

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256 _amount);

    function leaveStaking(uint256 _amount) external;

    function enterStaking(uint256 _amount) external;
}
