// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseAuction {
    address public immutable owner;
    uint public immutable AUCTION_COMISSION = 200; // 0.5%

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address ownerAddress) {
        owner = ownerAddress;
    }
}


contract BaseActiveAuction is BaseAuction {
    address public immutable mainContract;
    address public immutable rewardToken;
    uint256 public immutable rewardAmount;

    address public highestBidder;
    uint public highestBid;
    uint public auctionEarnings;
    bool public winnerGetPrise;
    bool public ended;

    modifier auctionActive() {
        require(!ended, "Auction already ended");
        _;
    }

    constructor(
        address ownerAddress, 
        address mainContractAddress, 
        address _rewardToken,
        uint256 _rewardAmount
    ) BaseAuction(ownerAddress) {
        mainContract = mainContractAddress;
        rewardToken = _rewardToken;
        rewardAmount = _rewardAmount;
        ended = false;
        winnerGetPrise = false;
        highestBid = 0;
        highestBidder = address(0);
        auctionEarnings = 0;
    }

    function withdrawReward() public payable returns (bool) {
        require(msg.sender == highestBidder, "Only the winner can withdraw the reward");
        require(ended, "Auction is not ended!");
        require(!winnerGetPrise, "Winner got reward already");
        
        require(IERC20(rewardToken).balanceOf(address(this)) >= rewardAmount, "Insufficient token balance");
        
        bool success = IERC20(rewardToken).transfer(msg.sender, rewardAmount);
        require(success, "Token transfer failed");
        
        winnerGetPrise = true;
        return true;
    }

    function withdrawAuctionEarnings(address sender) public payable {
        if (sender == owner && auctionEarnings > 0) {
            require(address(this).balance >= auctionEarnings, "Insufficient contract balance");

            (bool success, ) = payable(mainContract).call{value: auctionEarnings}("");
            require(success, "Transfer to mainContract failed");

            auctionEarnings = 0;
        }
    }
}