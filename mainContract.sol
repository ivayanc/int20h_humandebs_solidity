// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BaseAuction } from "./baseAuction.sol";
import { EnglishAuction } from "./englishAuction.sol";
import { DutchAuction } from "./dutchAuction.sol";
import { AuctionTypes, AuctionCreated, TokenCreated } from "./utils.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract AuctionSystem is BaseAuction{
    constructor() BaseAuction(msg.sender) {}

    receive() external payable {}

    function createAuction(
        address tokenAddress, uint256 tokenAmount, AuctionTypes auctionType, 
        uint _startPrice, uint _discountRate, uint _discountTimePeriod, uint _duration
    ) public returns (address) {
        require(tokenAmount > 0, "Err");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount), "TxF");
        
        address auctionAddress;
        
        if (auctionType == AuctionTypes.English) {
            auctionAddress = address(new EnglishAuction(
                msg.sender, address(this), tokenAddress, tokenAmount
            ));
        } else if (auctionType == AuctionTypes.Dutch) {
            auctionAddress = address(new DutchAuction(
                msg.sender, address(this), tokenAddress, tokenAmount,
                _startPrice, _discountRate, _discountTimePeriod, _duration
            ));
        } else {
            revert("Inv");
        }

        IERC20(tokenAddress).approve(auctionAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(auctionAddress, tokenAmount), "TxF");
        
        emit AuctionCreated(auctionType, msg.sender, tokenAddress, tokenAmount, auctionAddress);
        return auctionAddress;
    }

    function withdraw() public payable onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

}
