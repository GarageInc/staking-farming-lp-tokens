// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TAlphaToken is ERC20("TAlphaToken", "TALPHA"), Ownable {
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}
