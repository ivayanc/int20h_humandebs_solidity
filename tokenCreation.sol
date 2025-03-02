// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { TokenCreated } from "./utils.sol";

contract TokenCreation is ERC20 {
    constructor(
        string memory ticker, string memory name, uint256 initialSupply, address owner
    ) ERC20(name, ticker) {
        _mint(owner, initialSupply);
    }
    
}

contract TokenCreationFactory {
    function createToken(
        string memory ticker, string memory name, string memory description, string memory link,
        uint256 initialSupply
    ) public returns (address) {
        address tokenAddress = address(new TokenCreation(ticker, name, initialSupply, msg.sender));
        emit TokenCreated(ticker, name, description, link, initialSupply, msg.sender, tokenAddress);
        return tokenAddress;
    }
}
