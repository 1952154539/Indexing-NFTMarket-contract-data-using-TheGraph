// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title NFTMarket
/// @notice NFT marketplace with List/Sold events designed for TheGraph indexing
contract NFTMarket is ReentrancyGuard {
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        string tokenURL;
        address payToken;
        uint256 price;
        uint256 deadline;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    // fee in basis points (e.g., 250 = 2.5%)
    uint256 public feeBps;
    address public feeRecipient;

    event List(
        uint256 indexed listingId,
        address indexed nft,
        uint256 tokenId,
        string tokenURL,
        address indexed seller,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event Sold(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 fee
    );

    event ListingCancelled(uint256 indexed listingId);

    constructor(address _feeRecipient, uint256 _feeBps) {
        require(_feeBps <= 1000, "Fee too high"); // max 10%
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    /// @notice List an NFT for sale
    /// @param nftContract NFT contract address
    /// @param tokenId Token ID
    /// @param payToken ERC20 token address for payment (address(0) for native ETH)
    /// @param price Sale price
    /// @param deadline Listing expiration timestamp
    function list(
        address nftContract,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");
        require(deadline > block.timestamp, "Deadline must be in the future");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
                nft.getApproved(tokenId) == address(this),
            "Market not approved"
        );

        uint256 listingId = listingCounter++;

        string memory tokenURL = IERC721Metadata(nftContract).tokenURI(tokenId);

        listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            tokenURL: tokenURL,
            payToken: payToken,
            price: price,
            deadline: deadline,
            active: true
        });

        emit List(
            listingId,
            nftContract,
            tokenId,
            tokenURL,
            msg.sender,
            payToken,
            price,
            deadline
        );

        return listingId;
    }

    /// @notice Buy an NFT from a listing
    function buyNFT(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(block.timestamp <= listing.deadline, "Listing expired");
        require(msg.sender != listing.seller, "Cannot buy own NFT");

        listing.active = false;

        uint256 fee = (listing.price * feeBps) / 10000;
        uint256 sellerProceeds = listing.price - fee;

        if (listing.payToken == address(0)) {
            // Native ETH payment
            require(msg.value == listing.price, "Incorrect ETH amount");
            (bool success, ) = listing.seller.call{value: sellerProceeds}("");
            require(success, "Transfer to seller failed");
            if (fee > 0) {
                (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
                require(feeSuccess, "Transfer fee failed");
            }
        } else {
            // ERC20 payment
            IERC20 token = IERC20(listing.payToken);
            require(
                token.transferFrom(msg.sender, listing.seller, sellerProceeds),
                "Transfer to seller failed"
            );
            if (fee > 0) {
                require(
                    token.transferFrom(msg.sender, feeRecipient, fee),
                    "Transfer fee failed"
                );
            }
        }

        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        emit Sold(listingId, msg.sender, fee);
    }

    /// @notice Cancel an active listing
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;
        emit ListingCancelled(listingId);
    }

    /// @notice Get listing details
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }
}
