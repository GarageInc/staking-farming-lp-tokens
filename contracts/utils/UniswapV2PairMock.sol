// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapV2PairMock is ERC20("UniswapV2PairMock", "UNI-MOCK") {
    constructor() {}

    uint112 private reserve0 = 100 * 1e18; // uses single storage slot, accessible via getReserves
    uint112 private reserve1 = 200 * 1e18; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function setReserves(uint112 r0, uint112 r1) public {
        reserve0 = r0;
        reserve1 = r1;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}
