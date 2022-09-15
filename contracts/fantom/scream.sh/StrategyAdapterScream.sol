// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "./AlphaStrategyScream.sol";

contract StrategyAdapterScream is AlphaStrategyScream {
    function initialize(
        address _multisigWallet,
        address _rewardManager,
        address _treasury,
        address _underlying,
        address _vault,
        address _masterChef,
        address _controller
    ) public initializer {
        AlphaStrategyScream.initializeAlphaStrategy(
            _multisigWallet,
            _rewardManager,
            _treasury,
            _underlying,
            _vault,
            address(0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475),
            address(0xe3D17C7e840ec140a7A51ACA351a482231760824),
            _masterChef,
            _controller
        );
    }
}
