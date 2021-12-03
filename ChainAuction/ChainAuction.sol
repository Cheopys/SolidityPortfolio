// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Auction
{
    struct Bidder
    {
        address payable addressBidder;
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
    mapping(uint32 => Item)    public Items;
    mapping(address => Bidder) public Bidders;
    mapping(address => Seller) public Sellers;
    Item[]                     public ItemsHistory;
    address private administrator;
    
    constructor()
    {
        administrator = msg.sender;
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
        Items[itemIdNew] = Item({description: description, initialPrice: price, datePosted: block.timestamp, dateExpiration: expiration, bidHighest: Bid(Bidder(payable(msg.sender), ""), 0, 0)});
        seller.itemIds[seller.itemIds.length] = itemIdNew;
    }

    function processExpiredAuctions() payable public
    {
        Seller storage seller = Sellers[msg.sender];

        uint256 iItem = seller.itemIds.length;

        do 
        {
            uint32 itemId = seller.itemIds[--iItem];
            Item storage item = Items[itemId];

            if (item.dateExpiration > block.timestamp)
            {
                if (item.bidHighest.amount > item.initialPrice)
                {
                    item.bidHighest.bidder.addressBidder.transfer(item.bidHighest.amount);
                }

                delete Items[itemId];
                ItemsHistory.push(item);
            }
        } while (iItem > 0);
    }

    // called by Bidder
    
    function placeBid(uint32 itemId, string calldata emailBidder) public payable returns (bool)
    {
        Item storage item = Items[itemId];
        bool highest = false;

        if (msg.value > item.bidHighest.amount)
        {
            item.bidHighest.bidder.addressBidder = payable(msg.sender);
            item.bidHighest.bidder.email         = emailBidder;
            item.bidHighest.amount = msg.value;
            item.bidHighest.date   = block.timestamp;

            highest = true;
        }
        
        return highest;
    }
}
