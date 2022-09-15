// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "./BaseVault.sol";

contract BaseSinglePoolVault is BaseVault {
    function doHardWork() public override whenStrategyDefined {
        invest();
        IStrategy(strategy).stakeLpTokens();
        IStrategy(strategy).stakeFirstRewards();
    }
}
