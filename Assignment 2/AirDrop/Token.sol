// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    constructor(address _address) ERC20("ZeroToHero", "Z2H") {
        _mint(_address, 1000e18);
    }

}
