# Indexing NFTMarket Contract Data Using TheGraph

This project demonstrates how to use [TheGraph](https://thegraph.com/) to index on-chain data from an NFTMarket smart contract deployed on Sepolia testnet.

## Overview

- **NFTMarket**: A decentralized NFT marketplace contract that supports listing NFTs with ERC20 tokens or native ETH, with configurable trading fees.
- **TheGraph Subgraph**: Indexes `List` and `Sold` events from the NFTMarket contract, establishing relationships between listings and sales.

## Deployed Contracts (Sepolia Testnet)

| Contract   | Address                                      | Etherscan |
| ---------- | -------------------------------------------- | --------- |
| BaseERC20  | `0x55fA4367AD41290bc58425304901B619F127F069` | [Link](https://sepolia.etherscan.io/address/0x55fA4367AD41290bc58425304901B619F127F069#code) |
| SimpleNFT  | `0x25398bE0969E925fA9b554fA3042c5508E8F7873` | [Link](https://sepolia.etherscan.io/address/0x25398bE0969E925fA9b554fA3042c5508E8F7873#code) |
| NFTMarket  | `0xacc4e3E1dd37Fab686Ba9aEAA243882a88C52d37` | [Link](https://sepolia.etherscan.io/address/0xacc4e3E1dd37Fab686Ba9aEAA243882a88C52d37#code) |

## Smart Contract

### Events

```solidity
// Emitted when an NFT is listed for sale
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

// Emitted when an NFT is sold
event Sold(
    uint256 indexed listingId,
    address indexed buyer,
    uint256 fee
);

// Emitted when a listing is cancelled
event ListingCancelled(uint256 indexed listingId);
```

### Core Functions

| Function                                         | Description                              |
| ------------------------------------------------ | ---------------------------------------- |
| `list(nft, tokenId, payToken, price, deadline)`  | List an NFT for sale                     |
| `buyNFT(listingId)`                               | Purchase a listed NFT                    |
| `cancelListing(listingId)`                        | Cancel an active listing (seller only)   |
| `getListing(listingId)`                           | Get listing details                      |

## TheGraph Subgraph

### Entity Schema

```graphql
type List @entity(immutable: true) {
  id: Bytes!
  nft: Bytes!          # NFT contract address
  tokenId: BigInt!     # Token ID
  tokenURL: String!    # Token metadata URI
  seller: Bytes!       # Seller address
  payToken: Bytes!     # Payment token address
  price: BigInt!       # Sale price
  deadline: BigInt!    # Expiration timestamp
  blockNumber: BigInt!
  blockTimestamp: BigInt!
  transactionHash: Bytes!
  cancelTxHash: Bytes! # Set when listing is cancelled
  filledTxHash: Bytes! # Set when listing is sold
}

type Sold @entity(immutable: true) {
  id: Bytes!
  buyer: Bytes!        # Buyer address
  fee: BigInt!         # Platform fee
  blockNumber: BigInt!
  blockTimestamp: BigInt!
  transactionHash: Bytes!
  list: List!          # Relation to the listing
}
```

### Event Handlers

The subgraph maps three contract events to entity operations:

1. **`handleList`**: Creates a new `List` entity when `List` event is emitted
2. **`handleSold`**: Creates a new `Sold` entity and updates the related `List.filledTxHash`
3. **`handleListingCancelled`**: Updates `List.cancelTxHash`

This establishes a one-to-one relationship: each `Sold` record links back to its originating `List`.

## TheGraph Query Examples

### Query 1: Get All Active Listings

```graphql
{
  lists(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    nft
    tokenId
    tokenURL
    seller
    payToken
    price
    deadline
    blockTimestamp
  }
}
```

### Query 2: Get Sold Records with Listing Details

```graphql
{
  solds(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    buyer
    fee
    blockTimestamp
    transactionHash
    list {
      id
      nft
      tokenId
      tokenURL
      seller
      price
      payToken
    }
  }
}
```

### Query 3: Get Listings Cancelled After Being Created

```graphql
{
  lists(
    where: { cancelTxHash_not: "0x0000000000000000000000000000000000000000000000000000000000000000" }
    first: 10
  ) {
    id
    nft
    tokenId
    price
    seller
    cancelTxHash
    blockTimestamp
  }
}
```

### Query 4: Get Full Listing Lifecycle (Listed -> Sold)

```graphql
{
  solds(first: 5, orderBy: blockTimestamp, orderDirection: desc) {
    id
    buyer
    fee
    blockTimestamp
    transactionHash
    list {
      id
      nft
      tokenId
      tokenURL
      seller
      price
      payToken
      deadline
      blockTimestamp
      transactionHash
    }
  }
}
```

### Query 5: Get a Specific Listing by ID

```graphql
{
  list(id: "0x0") {
    id
    nft
    tokenId
    tokenURL
    seller
    payToken
    price
    deadline
    blockNumber
    blockTimestamp
    transactionHash
    cancelTxHash
    filledTxHash
  }
}
```

## Query Screenshots

_(Add TheGraph playground screenshots here showing query results)_

![Query Example 1](./screenshots/query1-listings.png)
![Query Example 2](./screenshots/query2-solds.png)

## Project Structure

```
.
├── src/
│   ├── BaseERC20.sol      # ERC20 token with callback support
│   ├── SimpleNFT.sol       # Simple ERC721 NFT for testing
│   └── NFTMarket.sol       # NFT marketplace contract
├── script/
│   └── Deploy.s.sol        # Foundry deployment script
├── subgraph/
│   ├── subgraph.yaml       # TheGraph manifest
│   ├── schema.graphql      # GraphQL entity schema
│   ├── src/
│   │   └── nft-market.ts   # AssemblyScript mappings
│   ├── package.json
│   └── tsconfig.json
├── foundry.toml            # Foundry configuration
└── README.md
```

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/)
- [Graph CLI](https://www.npmjs.com/package/@graphprotocol/graph-cli)

### Deploy Contracts

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export ETHERSCAN_API_KEY=your_etherscan_api_key

# Deploy to Sepolia
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

### Run Subgraph Locally

```bash
cd subgraph

# Install dependencies
npm install

# Generate types from schema and ABIs
npm run codegen

# Build the subgraph
npm run build
```

### Deploy Subgraph to TheGraph Studio

1. Create a subgraph on [TheGraph Studio](https://thegraph.com/studio/)
2. Authenticate: `graph auth --studio <DEPLOY_KEY>`
3. Deploy: `graph deploy --studio <SUBGRAPH_NAME>`

## License

MIT
