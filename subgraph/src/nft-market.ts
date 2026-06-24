import { BigInt, Bytes, store } from "@graphprotocol/graph-ts";
import {
  List as ListEvent,
  Sold as SoldEvent,
  ListingCancelled as ListingCancelledEvent,
} from "../generated/NFTMarket/NFTMarket";
import { List, Sold } from "../generated/schema";

export function handleList(event: ListEvent): void {
  let entity = new List(Bytes.fromHexString(event.params.listingId.toHexString()));
  entity.nft = event.params.nft;
  entity.tokenId = event.params.tokenId;
  entity.tokenURL = event.params.tokenURL;
  entity.seller = event.params.seller;
  entity.payToken = event.params.payToken;
  entity.price = event.params.price;
  entity.deadline = event.params.deadline;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.cancelTxHash = Bytes.empty();
  entity.filledTxHash = Bytes.empty();
  entity.save();
}

export function handleSold(event: SoldEvent): void {
  let entity = new Sold(Bytes.fromHexString(event.params.listingId.toHexString()));
  entity.buyer = event.params.buyer;
  entity.fee = event.params.fee;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.list = Bytes.fromHexString(event.params.listingId.toHexString());
  entity.save();

  // Update the List entity with filledTxHash
  let listEntity = List.load(Bytes.fromHexString(event.params.listingId.toHexString()));
  if (listEntity != null) {
    listEntity.filledTxHash = event.transaction.hash;
    listEntity.save();
  }
}

export function handleListingCancelled(event: ListingCancelledEvent): void {
  // Update the List entity with cancelTxHash
  let listEntity = List.load(Bytes.fromHexString(event.params.listingId.toHexString()));
  if (listEntity != null) {
    listEntity.cancelTxHash = event.transaction.hash;
    listEntity.save();
  }
}
