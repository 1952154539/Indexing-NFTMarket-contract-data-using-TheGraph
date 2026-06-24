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

## On-Chain Test Data

The following transactions were executed on Sepolia to generate real events for TheGraph indexing:

| # | Action | Tx Hash | Block |
|---|--------|---------|-------|
| 1 | **List** #0 (0.01 ETH) | `0x692ecd...01e80d` | [11127519](https://sepolia.etherscan.io/tx/0x692ecd0e124dbb2513e4460c381ab1a7d008f18b9e713c01db77513c9901e80d) |
| 2 | **Cancel** #0 | `0xd87b70...e8bc6` | [11127521](https://sepolia.etherscan.io/tx/0xd87b70e1071dac1a20cdb9bd9387a2957eda57d9488c86990e6c188f7aee8bc6) |
| 3 | **List** #1 (0.005 ETH) | `0xa65db0...06f1` | [11127524](https://sepolia.etherscan.io/tx/0xa65db05beeda3c025c2afde057da8134fe2e5ba6b522acded2588b1c580e06f1) |
| 4 | **Sold** #1 | `0xf73673...f005` | [11127528](https://sepolia.etherscan.io/tx/0xf73673bd5845841b19cca3d907f03c3fcc44d23d42131889a2adf826377af005) |

## TheGraph Query Examples

> After the subgraph syncs, the following queries will return the on-chain data shown above.

### Query 1: Get All Listings

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
    cancelTxHash
    filledTxHash
  }
}
```

**Expected Result:**

```json
{
  "data": {
    "lists": [
      {
        "id": "0x0000000000000000000000000000000000000000000000000000000000000001",
        "nft": "0x25398be0969e925fa9b554fa3042c5508e8f7873",
        "tokenId": "1",
        "tokenURL": "https://ipfs.io/ipfs/QmTest2",
        "seller": "0xc7a263b1205226158b7a5f8aa8fdbaae9c15a55d",
        "payToken": "0x0000000000000000000000000000000000000000",
        "price": "5000000000000000",
        "deadline": "1782880289",
        "cancelTxHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "filledTxHash": "0xf73673bd5845841b19cca3d907f03c3fcc44d23d42131889a2adf826377af005"
      },
      {
        "id": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "nft": "0x25398be0969e925fa9b554fa3042c5508e8f7873",
        "tokenId": "1",
        "tokenURL": "https://ipfs.io/ipfs/QmTest2",
        "seller": "0xc7a263b1205226158b7a5f8aa8fdbaae9c15a55d",
        "payToken": "0x0000000000000000000000000000000000000000",
        "price": "10000000000000000",
        "deadline": "1782880016",
        "cancelTxHash": "0xd87b70e1071dac1a20cdb9bd9387a2957eda57d9488c86990e6c188f7aee8bc6",
        "filledTxHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
      }
    ]
  }
}
```

### Query 2: Get Sold Records with Listing Details (Relational Query)

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

**Expected Result:**

```json
{
  "data": {
    "solds": [
      {
        "id": "0x0000000000000000000000000000000000000000000000000000000000000001",
        "buyer": "0xe6d606709241c6927d0a2270e098262a657bfacc",
        "fee": "125000000000000",
        "blockTimestamp": "1769055512",
        "transactionHash": "0xf73673bd5845841b19cca3d907f03c3fcc44d23d42131889a2adf826377af005",
        "list": {
          "id": "0x0000000000000000000000000000000000000000000000000000000000000001",
          "nft": "0x25398be0969e925fa9b554fa3042c5508e8f7873",
          "tokenId": "1",
          "tokenURL": "https://ipfs.io/ipfs/QmTest2",
          "seller": "0xc7a263b1205226158b7a5f8aa8fdbaae9c15a55d",
          "price": "5000000000000000",
          "payToken": "0x0000000000000000000000000000000000000000"
        }
      }
    ]
  }
}
```

### Query 3: Get Cancelled Listings

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

**Expected Result:**

```json
{
  "data": {
    "lists": [
      {
        "id": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "nft": "0x25398be0969e925fa9b554fa3042c5508e8f7873",
        "tokenId": "1",
        "price": "10000000000000000",
        "seller": "0xc7a263b1205226158b7a5f8aa8fdbaae9c15a55d",
        "cancelTxHash": "0xd87b70e1071dac1a20cdb9bd9387a2957eda57d9488c86990e6c188f7aee8bc6",
        "blockTimestamp": "1769055428"
      }
    ]
  }
}
```

### Query 4: Get Full Listing Lifecycle

```graphql
{
  list(id: "0x0000000000000000000000000000000000000000000000000000000000000001") {
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

**Expected Result (List #1: Listed → Sold):**

```json
{
  "data": {
    "list": {
      "id": "0x0000000000000000000000000000000000000000000000000000000000000001",
      "nft": "0x25398be0969e925fa9b554fa3042c5508e8f7873",
      "tokenId": "1",
      "tokenURL": "https://ipfs.io/ipfs/QmTest2",
      "seller": "0xc7a263b1205226158b7a5f8aa8fdbaae9c15a55d",
      "payToken": "0x0000000000000000000000000000000000000000",
      "price": "5000000000000000",
      "deadline": "1782880289",
      "blockNumber": "11127524",
      "blockTimestamp": "1769055464",
      "transactionHash": "0xa65db05beeda3c025c2afde057da8134fe2e5ba6b522acded2588b1c580e06f1",
      "cancelTxHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "filledTxHash": "0xf73673bd5845841b19cca3d907f03c3fcc44d23d42131889a2adf826377af005"
    }
  }
}
```

### Data Relationship Diagram

```
List #0 ── canceled ── cancelTxHash = 0xd87b70...e8bc6
List #1 ── sold ──→ Sold #1
                     │  buyer: 0xe6D6...bfacC
                     │  fee:   0.000125 ETH (2.5%)
                     │
                     └── list → List #1 (reverse relation)
```

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
