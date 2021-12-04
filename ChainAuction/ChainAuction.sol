    // SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ChainAuction
{
    struct Bidder
    {
        string  email;
        Bid[]   bids;
    }
    
    struct Bid
    {
        address addressBidder;
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
        uint32[] itemIdsHistory;
    }
    
    struct EtherOwedToSeller
    {
        uint256 amountOwed;
        address sellerOwed;
    }

    uint32  private itemCount;
    mapping(uint32  => Item)   public Items;
    mapping(uint32  => Item)   public ItemsHistory;
    mapping(address => Bidder) public Bidders;
    mapping(address => Seller) public Sellers;

    // administrator

    address private administrator;
    EtherOwedToSeller[] private etherOwed;

    Item[] private ItemsRemoved;

    constructor()
    {
        administrator = msg.sender;
    }

    event EtherOwedSeller(uint256 amount, Seller seller);

    modifier isAdministrator() 
    {
        require(msg.sender == administrator);
        _;
    }

    // administrator functions

    function addSeller(address payable sellerNew, string memory emailNew) public isAdministrator
    {
        Seller memory seller;
        
        seller.email = emailNew;
        
        Sellers[sellerNew] = seller;
    }

    function paySellers() public payable isAdministrator
    {
        while (etherOwed.length > 0)
        {
            EtherOwedToSeller storage owed = etherOwed[etherOwed.length - 1];

            payable(owed.sellerOwed).transfer(owed.amountOwed);

            etherOwed.pop();
        }
    }

    // SELLER functions
    // called by seller, who must provide current time based on his own machine
    
    function addItem(string  calldata description, 
                     uint256 price, 
                     uint256 currentTime,
                     uint256 expiration) public 
    {
        require(expiration > block.timestamp);

        uint32 itemIdNew = itemCount++;
        Seller storage seller    = Sellers[msg.sender];
        Items[itemIdNew] = Item({description: description, initialPrice: price, datePosted: currentTime, dateExpiration: expiration, bidHighest: Bid(msg.sender, 0, 0)});
        seller.itemIds[seller.itemIds.length] = itemIdNew;
    }

    function getSellerBids() public view returns (Item[] memory)
    {
        Seller memory seller = Sellers[msg.sender];
        Item[] memory items = new Item[](seller.itemIds.length);
        uint iItem;

        while (iItem < seller.itemIds.length)
        {
            items[iItem] = Items[seller.itemIds[iItem]];

            iItem++;
        }

        return items;
    }

    function processExpiredAuctions(uint256 currentTime) payable public returns(Item[] memory)
    {
        Seller storage seller = Sellers[msg.sender];

        uint256 iItem = seller.itemIds.length;
        uint256 amount;

        delete ItemsRemoved;

        do 
        {
            uint32 itemId = seller.itemIds[--iItem];
            Item storage item = Items[itemId];

            if (item.dateExpiration > currentTime)
            {
                if (item.bidHighest.amount > item.initialPrice)
                {
                    amount += item.bidHighest.amount;
                    payable(item.bidHighest.addressBidder).transfer(item.bidHighest.amount);
                }

                moveItemToHistory(seller, itemId, item);
            }
        } while (iItem > 0);

        Item[] memory ItemsRemovedMemory = ItemsRemoved;

        // alert administrator to pay seller

        if (amount > 0)
        {
            EtherOwedToSeller memory owed;
            owed.amountOwed = amount;
            owed.sellerOwed = msg.sender;

            etherOwed.push(owed);
            emit EtherOwedSeller(amount, seller);
        }

        delete ItemsRemoved;

        return ItemsRemovedMemory;
    }

    function moveItemToHistory(Seller storage seller, uint32 itemId, Item storage item) private
    {
        // move between state variables

        ItemsHistory[itemId] = item;
        delete Items[itemId];

        // move betweeen seller variables

        seller.itemIdsHistory.push(itemId);
        ItemsHistory[itemId] = item;
    }

    // called by Bidder

    function registerBidder(string memory emailNew) public
    {
        Bidder storage bidder = Bidders[msg.sender];

        require(bidder.bids.length == 0);

        bidder.email = emailNew;

        Bidders[msg.sender] = bidder;
    }

    function placeBid(uint32 itemId, uint256 currentTime) public payable returns (bool)
    {
        Item storage item = Items[itemId];
        bool highest = false;

        if (msg.value > item.bidHighest.amount)
        {
            item.bidHighest.addressBidder = msg.sender;
            item.bidHighest.amount        = msg.value;
            item.bidHighest.date          = currentTime;

            highest = true;
        }
        
        return highest;
    }
}
