// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Auction
{
    struct Bidder
    {
        address addressBidder;
        string  email;
    }
    
    struct Bid
    {
        Bidder  bidder;
        uint256 amount;
        uint256 date;
    }

    struct Item
    {
        string  description;
        uint256 initialPrice;
        uint256 datePosted;
        uint256 dateExpiration;
        Bid     bidHighest;
    }
    
    struct Seller
    {
        string   email;
        uint32[] itemIds;
    }
    
    uint32  private itemCount;
    mapping(uint32 => Item) public Items;
    mapping(address => Bidder) public  Bidders;
    mapping(address => Seller) public  Sellers;
    address private administrator;
    Bid private emptyBid;
    
    constructor()
    {
        administrator = msg.sender;
        emptyBid      = Bid(Bidder(msg.sender, ""), 0, 0);
    }

    modifier isAdministrator() 
    {
        require(msg.sender == administrator);
        _;
    }

    function addSeller(address sellerNew, string memory emailNew) public isAdministrator
    {
        Seller memory seller;
        
        seller.email = emailNew;
        
        Sellers[sellerNew] = seller;
    }

    // called by seller
    
    function addItem(string  calldata description, 
                     uint256 price, 
                     uint256 expiration) public 
    {
        require(expiration > block.timestamp);
        
        uint32 itemIdNew = itemCount++;
        Seller storage seller    = Sellers[msg.sender];
        Items[itemIdNew] = Item({description: description, initialPrice: price, datePosted: block.timestamp, dateExpiration: expiration, bidHighest: emptyBid});
        seller.itemIds[seller.itemIds.length] = itemIdNew;
    }
    
    // called by Bidder
    
    function placeBid(uint32 itemId, string calldata emailBidder) public payable returns (bool)
    {
        Item storage item = Items[itemId];
        bool highest = false;

        if (msg.value > item.bidHighest.amount)
        {
            item.bidHighest.bidder.addressBidder = msg.sender;
            item.bidHighest.bidder.email         = emailBidder;
            item.bidHighest.amount = msg.value;
            item.bidHighest.date   = block.timestamp;

            highest = true;
        }
        
        return highest;
    }
}