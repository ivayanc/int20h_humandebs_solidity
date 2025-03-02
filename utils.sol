// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Enums
enum AuctionTypes { 
    English, 
    TimeBased,
    SealedBid, 
    Dutch 
}


// Events
event AuctionCreated(AuctionTypes auctionType, address owner, address tokenAddress, uint256 tokenAmount, address auctionAddress);
event HighestBidIncreased(address bidder, uint amount);
event SealedBidPlaced(address bidder, bytes32 sealedBid);
event BidRevealed(address bidder, uint amount);
event AuctionEnded(address winner, uint amount);

event TokenCreated(string ticker, string name, string description, string link, uint256 initialSupply, address owner, address contractAddress);
