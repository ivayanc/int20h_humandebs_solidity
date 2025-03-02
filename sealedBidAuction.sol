// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BaseActiveAuction } from "./baseAuction.sol";
import { SealedBidPlaced, BidRevealed, HighestBidIncreased, AuctionEnded } from "./utils.sol";

contract SealedBidAuction is BaseActiveAuction{
    
    uint public immutable biddingDuration;
    uint public immutable revealDuration;
    uint public immutable auctionEndTime;
    uint public immutable auctionRevealTime;

    struct Bid {
        bytes32 sealedBid;
        uint deposit;
    }

    mapping(address => Bid) private bids;


    modifier onlyBeforeAuctionEnd() {
        require(block.timestamp < auctionEndTime, "Auction already expired.");
        _;
    }

    modifier onlyAfterAuctionEnd() {
        require(block.timestamp >= auctionEndTime, "Auction not yet expired.");
        _;
    }


    modifier onlyBeforeRevealEnd() {
        require(block.timestamp < auctionRevealTime, "Auction not yet expired.");
        _;
    }

    modifier onlyAfterRevealEnd() {
        require(block.timestamp >= auctionRevealTime, "Auction not yet expired.");
        _;
    }

    constructor(address ownerAddress, address mainContractAddress, uint reward, uint _biddingDuration, uint _revealDuration) BaseActiveAuction(ownerAddress, mainContractAddress, reward) {
        biddingDuration = _biddingDuration;
        revealDuration = _revealDuration;
        auctionEndTime = block.timestamp + _biddingDuration;
        auctionRevealTime = auctionEndTime + _revealDuration;
    }

    
    function placeBid(string memory _secret) public payable onlyBeforeAuctionEnd auctionActive {
        require(msg.value > 0, "Must send a deposit");
        require(bids[msg.sender].sealedBid == bytes32(0), "Bid already submitted");
        require(msg.sender.balance >= msg.value, "Insufficient balance");

        bytes32 _sealedBid = keccak256(abi.encodePacked(msg.value, _secret));
        bids[msg.sender] = Bid({sealedBid: _sealedBid, deposit: msg.value});
        emit SealedBidPlaced(msg.sender, _sealedBid);
    }


    function revealBid(string memory _secret) public onlyAfterAuctionEnd onlyBeforeRevealEnd auctionActive {
        uint _value = bids[msg.sender].deposit;
        bytes32 _sealedBid = bids[msg.sender].sealedBid;
        require(_sealedBid != bytes32(0) || _value != 0, "No bid to reveal");

        bytes32 computedHash = keccak256(abi.encodePacked(_value, _secret));
        require(computedHash == _sealedBid, "Invalid bid secret code");
        emit BidRevealed(msg.sender, _value);

        if (_value > highestBid) {
            highestBid = _value;
            highestBidder = msg.sender;
            emit HighestBidIncreased(highestBidder, highestBid);
        }
    }


    function endAuction() public onlyOwner onlyAfterAuctionEnd onlyAfterRevealEnd auctionActive {
        require(!ended, "Auction already ended");
        ended = true;
        auctionEarnings = highestBid / AUCTION_COMISSION;
        bids[msg.sender].deposit += highestBid - auctionEarnings;
        emit AuctionEnded(highestBidder, highestBid);
    }


    function withdraw() public payable onlyAfterAuctionEnd onlyAfterRevealEnd returns (bool) {
        uint amount = bids[msg.sender].deposit;
        require(amount > 0, "No funds to withdraw");
        require(ended, "Auction is not ended!");
        require(highestBidder != msg.sender, "Winner can not withdraw funds!");
        
        withdrawAuctionEarnings(msg.sender);

        bids[msg.sender].deposit = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            bids[msg.sender].deposit = amount;
            return false;
        }
        bids[msg.sender].sealedBid = bytes32(0);
        return true;
    }


    function getTimeAuctionLeft() public view auctionActive returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }

    function getTimeRevealLeft() public view auctionActive returns (uint) {
        if (block.timestamp >= auctionRevealTime) {
            return 0;
        } else {
            return auctionRevealTime - block.timestamp;
        }
    }

}