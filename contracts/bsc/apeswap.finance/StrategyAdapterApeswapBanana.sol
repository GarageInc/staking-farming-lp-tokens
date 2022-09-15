// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "./AlphaStrategyApeswap.sol";

contract StrategyAdapterApeswapBanana is AlphaStrategyApeswap {
    function initialize(
        address _underlying,
        address _vault,
        uint256 _pidLP
    ) public initializer {
        AlphaStrategyApeswap.initializeAlphaStrategy(
            address(0x3EDde7123c29Bd05273F743083782DE3C818bF36),
            address(0x7F1c2432Dc4e83b49fA0Ec85ae45470D6B17b67F),
            address(0x3EDde7123c29Bd05273F743083782DE3C818bF36),
            _underlying,
            _vault,
            address(0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9),
            address(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95),
            _pidLP,
            0
        );
    }
}
