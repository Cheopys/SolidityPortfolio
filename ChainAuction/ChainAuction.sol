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
        uint32  itemId;
        uint256 amount;
        uint32  date;
    }

    struct Item
    {
        uint32  itemId;
        string  description;
        uint256 initialPrice;
        uint32  datePosted;
        uint32  dateExpiration
        Bid     bidHighest;
    }
    
    struct Seller
    {
        address addressBidder;
        string  email;
        Item[]  items;
    }
    
    uint32  private itemCount;
    mapping public  Items(uint32 => Item);
    mapping public  Bidders(address => Bidder);
    address private administrator;
    
    constructor()
    {
        administrator = msg.sender;
    }
    
    function addItem(string email, string description, uint256 price, uint32 expiration) public 
    {
        require(expiration > block.timestamp);
        
        Bidder bidder = bidders[msg.sender];
        
        if (bidder.email == "")
        {
            bidder.email = email
        }
        
        bidder.Items.push(Item({iotemId: itemCount++, descrption: description, initialPrice: price, datePosted: block.timestamp, dateExpiration: expiration}))
    }

    // called by external JS code on clock tick

    function processExpiredAuctions() public returns (uint)
    {
    }

}