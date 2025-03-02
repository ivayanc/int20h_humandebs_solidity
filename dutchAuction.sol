// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BaseActiveAuction } from "./baseAuction.sol";
import { HighestBidIncreased, AuctionEnded } from "./utils.sol";

contract DutchAuction is BaseActiveAuction{
    
    uint public immutable startPrice;    
    uint public immutable discountRate;
    uint public immutable discountTimePeriod;
    uint public immutable auctionStartTime;         
    uint public immutable auctionEndTime;       
    uint public immutable duration;

    mapping(address => uint) public pendingReturns;

    modifier onlyBeforeAuctionEnd() {
        require(block.timestamp < auctionEndTime, "Auction already expired.");
        _;
    }

    constructor(
        address ownerAddress, 
        address mainContractAddress, 
        address _rewardToken,
        uint256 _rewardAmount,
        uint _startPrice, 
        uint _discountRate, 
        uint _discountTimePeriod, 
        uint _duration
    ) BaseActiveAuction(ownerAddress, mainContractAddress, _rewardToken, _rewardAmount) {
        require(_startPrice >= _discountRate * (_duration / _discountTimePeriod), "Start price is too low");
        startPrice = _startPrice;
        discountRate = _discountRate;
        discountTimePeriod = _discountTimePeriod;
        duration = _duration;
        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + _duration;
    }

    
    function getPrice() public view returns (uint256) {
        uint timeElapsed = block.timestamp - auctionStartTime;
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return startPrice - discountRate * (timeElapsed / discountTimePeriod);
        }
    }

    
    function placeBid() public payable onlyBeforeAuctionEnd auctionActive() {
        require(msg.sender.balance >= msg.value, "Insufficient balance");

        uint currentPrice = getPrice();
        require(msg.value >= currentPrice, "Insufficient ETH sent");

        highestBidder = msg.sender;
        highestBid = currentPrice;

        emit HighestBidIncreased(highestBidder, highestBid);

        ended = true;
        auctionEarnings = highestBid / AUCTION_COMISSION;
        pendingReturns[owner] = highestBid - auctionEarnings;
        emit AuctionEnded(highestBidder, highestBid);
        
        if (msg.value > currentPrice) {
            pendingReturns[msg.sender] = msg.value - currentPrice;
        }
    }


    function withdraw() public payable returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        require(ended, "Auction is not ended!");
        
        withdrawAuctionEarnings(msg.sender);

        pendingReturns[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            pendingReturns[msg.sender] = amount;
            return false;
        }
        return true;
    }


    function getTimeLeft() public view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }

}