// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BaseActiveAuction } from "./baseAuction.sol";
import { HighestBidIncreased, AuctionEnded } from "./utils.sol";

contract EnglishAuction is BaseActiveAuction{
    
    mapping(address => uint) public pendingReturns;

    constructor(
        address ownerAddress, 
        address mainContractAddress, 
        address _rewardToken,
        uint256 _rewardAmount
    ) BaseActiveAuction(ownerAddress, mainContractAddress, _rewardToken, _rewardAmount) {}
    
    function bid() public payable auctionActive {
        require(msg.value + pendingReturns[msg.sender] > highestBid, "There already is a higher bid");
        require(msg.sender.balance >= msg.value, "Insufficient balance");
        
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] = highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value + pendingReturns[msg.sender];
        emit HighestBidIncreased(msg.sender, msg.value + pendingReturns[msg.sender]);
    }

    function endAuction() public onlyOwner {
        require(!ended, "Auction already ended");
        ended = true;
        auctionEarnings = highestBid / AUCTION_COMISSION;
        pendingReturns[msg.sender] += highestBid - auctionEarnings;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdraw() public payable returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        require(ended, "Auction is not ended!");
        require(highestBidder != msg.sender, "Winner can not withdraw funds!");
        require(address(this).balance >= amount, "Insufficient contract balance");

        withdrawAuctionEarnings(msg.sender);

        pendingReturns[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            pendingReturns[msg.sender] = amount;
            return false;
        }
        return true;
    }

}