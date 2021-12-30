    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.2;

    import "@openzeppelin/contracts@4.4.1/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts@4.4.1/token/ERC721/extensions/ERC721Enumerable.sol";
    import "@openzeppelin/contracts@4.4.1/access/Ownable.sol";

    contract RemitanoNFT is ERC721, ERC721Enumerable, Ownable, IERC721Receiver 
    {
        constructor() ERC721("RemitanoNFT", "RNFT") 
        {
            // ownable interface manages owner
        }

        //  string(abi.encodePacked(tokenURIPrefix,uint2str(_tokenId)))

        function _baseURI() internal pure override returns (string memory) 
        {
            return "https://ipfs.io/ipfs/QmaWedG9pgCz85UDU3dexuqawU44CMSCDdfJ28fsHBe4AK";
        }
        
        // TBD: solidity errors with AND without ERC721Metadata included;
        //      return to this later

        function _tokenURI(uint256 tokenID) internal pure returns (string memory)
        {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenID)));
        }
        
        //
        // contract tokens
        //

        uint256 priceContractToken = 1000000;

        // required for tokens belonging to the contract

        function onERC721Received(address, // operator, 
                                address from, 
                                uint256 tokenID, 
                                bytes calldata  data) override(IERC721Receiver) public returns(bytes4)
        {
            addTokenListing(from, priceContractToken, tokenID, data);

            return this.onERC721Received.selector;
        }
        // call repeatedly for different prices

        function addContractTokens(uint256 count, bytes calldata data) onlyOwner public returns (uint256)
        {
            uint256 iToken = 0;
            uint256 tokenID;

            while(iToken < count)
            {
                tokenID = newTokenID();

                // storage listing done by onERC721Received

                _safeMint(address(this), tokenID, data);
    //          _setTokenURI(tokenID, _tokenURI(tokenID));
                iToken = iToken + 1;
            }

            return totalSupply();
        }

        // not certain why this is necessary

        struct Listing
        {
            address  owner;
            uint256  price;
            uint256  tokenID;
            bytes    data;
        }

        Listing listingNotFound;

        address[] creators;

        function addCreator(address creator) public onlyOwner
        {
            require(isCreator(creator) == false);
            
            creators.push(creator);
        }

        function isCreator(address creator) public view onlyOwner returns (bool)
        {
            uint256 iCreator = 0;
            bool    isaCreator = false;

            while(iCreator < creators.length)
            {
                if (creators[iCreator] == creator)
                {
                    isaCreator = true;
                    break;
                }
            }

            return isaCreator;
        }
        // map content creators to their NFTs

        mapping(address => Listing[]) listings;

        //
        // manage the contract's internal storage
        //

        function addTokenListing(address owner, 
                                uint256 price, 
                                uint256 tokenID,
                                bytes calldata data) internal returns (Listing memory)
        {
            Listing memory listing = Listing({ owner: owner, price: price, tokenID: tokenID, data: data });
            listings[owner].push(listing);
    //      _setTokenURI(tokenID, _tokenURI(tokenID)); TBD: wasted enough time trying to get this to compile
            return listing;
        }

        function removeTokenListing(address owner, uint256 tokenID) internal returns (Listing memory)
        {
            require(listings[owner].length > 0, "no tokens for owner");
            Listing memory listingRemoved;
            uint256 iListing = 0;

            while(iListing < listings[owner].length)
            {
                if (listings[owner][iListing].tokenID == tokenID)
                {
                    // found it; 
                    // * save a memory copy
                    // * replace it with the last one in the array
                    // * pop() the last one to shorten the array

                    listingRemoved = listings[owner][iListing];
                    listings[owner][iListing] = listings[owner][listings[owner].length - 1];
                    listings[owner].pop();
                    break;
                }

                iListing = iListing + 1;
            }

            require(iListing < listings[owner].length, "token not found for owner");
            return listingRemoved;
        }

        //
        // TEST CODE - remove before mainnet deployment
        //

        function tokensForContract() public view returns (Listing[] memory)
        {
            Listing[] memory listingsContract = listings[address(this)];
            return listingsContract;
        }

        function tokensForOwner() public view returns (Listing[] memory)
        {
            Listing[] memory listingsOwner = listings[msg.sender];
            return listingsOwner;
        }

        function contractID() public view returns (address)
        {
            return address(this);
        }

        function creatorIDs() public view returns (address[] memory)
        {
            return creators;
        }

        //
        // END TEST CODE
        //

        // The following function overrides are required

        function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
        {
            super._beforeTokenTransfer(from, to, tokenId);
        }

        function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
        {
            return super.supportsInterface(interfaceId);
        }
        
        //
        // owner
        ///

        // - Us to list NFT from various content creators (Assume that we will help to distribute the NFT with a consent price).

        //
        // primitive mutex to prevent reentrancy
        //

        mapping (address => bool) processing; // guard against reentrancy

        //
        // not implemented as a modifier because it must not precede any requires 
        // or the release will never be called

        function takeMutex() internal returns(bool)
        {
            bool taken = false;

            require(processing[msg.sender] == false);

            processing[msg.sender] = true;
            taken = true;

            return taken;
        }

        function releaseMutex() internal
        {
            processing[msg.sender] = false;
        }

        function tokensforCreator(address creator) public view onlyOwner returns (Listing[] memory)
        {
            return listings[creator];
        }
        
        // returns storage because caller probably wants to modify data

        function listingForToken(uint256 tokenID) private view returns (Listing storage)
        {
            require(_exists(tokenID), "token does not exist");
            address owner = ownerOf(tokenID);
            require(listings[owner].length > 0, "owner has no tokens in contract");
            uint256 iListing = 0;
            Listing storage listing = listingNotFound;

            while(iListing < listings[owner].length)
            {
                if (listings[owner][iListing].tokenID == tokenID)
                {
                    listing = listings[owner][iListing];
                    break;
                }

                iListing++;
            }

            // this should not happen but check anyway

            require(iListing < listings[owner].length, "token not found");

            return listing;
        }

        // cardinal count is highest ordinal plus one

        function newTokenID() internal view returns (uint256)
        {
            return totalSupply();
        }

        function setTokenPrice(uint256 tokenID, uint256 priceNew) public 
        {
            Listing storage listing = listingForToken(tokenID);

            listing.price = priceNew;
        }

        function tokenPrice(uint256 tokenID) public view returns (uint256)
        {
            Listing memory listing = listingForToken(tokenID);
            return listing.price;
        }

        //
        // investor
        //

        // add a new token, return its ID

        function addToken(uint256 price, bytes calldata data, bool save) internal returns (uint256)
        {
            // count = highest zero-based index plus one
            uint256 tokenIDNew = newTokenID();

            takeMutex();
            _safeMint(msg.sender, tokenIDNew, data);
            releaseMutex();

            require(_exists(tokenIDNew), "token was not minted");

            if (save)
            {
                addTokenListing(msg.sender, price, tokenIDNew, data);
            }

            return tokenIDNew;
        }

        // investors can mint new token

        function mintToken(uint256 price, bytes calldata data) public returns (uint256)
        {
            return addToken(price, data, true);
        }

        // - mint and send tokens (one function)
        // data is metadata TBD integrate with IPFS
        // since token will be transfewrred immediately, don't add it to the contract's listingNotFound

        function mintAndSend(address payable recipient, 
                            uint256         price,
                            bytes calldata  data) payable public returns (uint256 tokenID) // TBD: migrate to IPFS
        {
            require(recipient.balance > price, "insufficient funds");
            uint256 tokenIDNew = addToken(price, data, false);

            payable(msg.sender).transfer(price);

            _beforeTokenTransfer(msg.sender, recipient, tokenIDNew);
            safeTransferFrom   (msg.sender, recipient, tokenIDNew, data);
            
            return tokenIDNew;
        }

        // - Investors buy NFTs from Us. TBD: us?  any NFT or just contract NFTs?

        function buyToken(uint256 tokenID, bytes calldata data) public payable 
        {
            require(_exists(tokenID), "token does not exist");
            address tokenOwner = ownerOf(tokenID);
            uint256 price      = tokenPrice(tokenID);
            require(msg.value > price, "insufficient funds");
            approve(msg.sender, tokenID);

            // TBD: transfer and send are deprecated, change to call(value: )("" )

            takeMutex();
            payable(tokenOwner).transfer(price);
            releaseMutex();

            _beforeTokenTransfer(tokenOwner, msg.sender, tokenID);

            safeTransferFrom(tokenOwner, msg.sender, tokenID, data);

            // update the token metadata

            Listing storage listing = listingForToken(tokenID);

            listing.owner = msg.sender;
            listing.data  = data;
        }

        function sellToken(address recipient, 
                        uint256 tokenID, 
                        bytes calldata data) public payable 
        {
            require(_exists(tokenID), "token does not exist");
            address tokenOwner = ownerOf(tokenID);
            require(tokenOwner == msg.sender, "caller does not own token");
            uint256 price      = tokenPrice(tokenID);
            require(recipient.balance > price, "insufficient funds");
            
            // TBD: transfer and send are deprecated, change to call(value: )("" )

            payable(msg.sender).transfer(price);

            approve(recipient, tokenID);

            _beforeTokenTransfer(msg.sender, recipient, tokenID);

            safeTransferFrom(msg.sender, recipient, tokenID, data);

            // update the token metadata

            Listing storage listing = listingForToken(tokenID);

            listing.owner = recipient;
            listing.data  = data;
        }
    }
