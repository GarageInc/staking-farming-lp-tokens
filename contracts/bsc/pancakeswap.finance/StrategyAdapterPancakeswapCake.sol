// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "./AlphaStrategyPancakeswap.sol";

contract StrategyAdapterPancakeswapCake is AlphaStrategyPancakeswap {
    function initialize(
        address _underlying,
        address _vault,
        uint256 _pidLP
    ) public initializer {
        AlphaStrategyPancakeswap.initializeAlphaStrategy(
            address(0x3EDde7123c29Bd05273F743083782DE3C818bF36),
            address(0x7F1c2432Dc4e83b49fA0Ec85ae45470D6B17b67F),
            address(0x3EDde7123c29Bd05273F743083782DE3C818bF36),
            _underlying,
            _vault,
            address(0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652), // masterchefV1
            address(0x45c54210128a065de780C4B0Df3d16664f7f859e), // masterchefV2
            address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // Cake
            _pidLP
        );
    }
}
