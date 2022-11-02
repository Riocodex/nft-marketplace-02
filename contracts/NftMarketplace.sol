//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketPlace();
error NftMarketplace__AlreadyListed(address nftAddress , uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress , uint256 tokenId);
error NftMarketplace__PriceNotMet(address nftAddress , uint256 tokenId , uint256 price);

contract NftMarketplace{

    struct Listing{
        uint256 price;
        address seller; 
    }

        event ItemListed(
            address indexed seller,
            address indexed nftAddress,
            uint256 indexed tokenId,
            uint256 price
        );

    //NFT Contract address -> NFT TokenID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

        ///////////////////
        // MODIFIERS //
    /////////////////////
    //this makes sure an nft that has been listed cant be listed again
    modifier notListed(address nftAddress , uint256 tokenId, address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0){
            revert NftMarketplace__AlreadyListed(nftAddress , tokenId);
        }
        _;
    }

    //this checks the owner of the nft..to make sure that only the owner of the nft can list it
    modifier isOwner(address nftAddress , uint256 tokenId , address spender){
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner){
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    modifier isListed(address nftAddress , uint256 tokenId){
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.price <=0 ){
            revert NftMarketplace__NotListed(nftAddress , tokenId);
        }
    }
        
    ///////////////////
    // MAIN FUNCTIONS //
    /////////////////////


    /**
     * @notice Method for lifiting your NFT on the marketplace
     * @param nftAddress: Address of the NFT
     * @param tokenId: the Token ID of the nft
     * @param price: sale price of the nft
     * @dev Technically, we could have the contract be the escrow for the NFTs
     * but this way people can still hold their NFTs when listed
     */

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external 
    notListed(nftAddress , tokenId , msg.sender)
    isOwner(nftAddress , tokenId , msg.sender){
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
            IERC721 nft = IERC721(nftAddress);
            if (nft.getApproved(tokenId) != address(this)){
                revert NftMarketplace__NotApprovedForMarketPlace();
            }
            s_listings[nftAddress][tokenId] = Listing(price ,msg.sender);
            emit ItemListed(msg.sender , nftAddress , tokenId , price);
        }
    }

    function buyItem(address nftAddress , uint256 tokenId) external payable{
        external
        payable
        isListed(nftAddress , tokenId)
        {
            Listing memory listedItem = s_listings[nftAddress][tokenId];
            if(msg.value < listedItem.price){
                revert NftMarketplace__PriceNotMet(nftAddress , tokenId , listedItem.price);
            }
        }
    }
}