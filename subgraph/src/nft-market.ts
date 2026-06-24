import { BigInt, Bytes, ByteArray, store } from "@graphprotocol/graph-ts";
import {
  List as ListEvent,
  Sold as SoldEvent,
  ListingCancelled as ListingCancelledEvent,
} from "../generated/NFTMarket/NFTMarket";
import { List, Sold } from "../generated/schema";

function listingIdToBytes(id: BigInt): Bytes {
  return Bytes.fromByteArray(Bytes.fromBigInt(id));
}

export function handleList(event: ListEvent): void {
  let id = listingIdToBytes(event.params.listingId);
  let entity = new List(id);
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
  let id = listingIdToBytes(event.params.listingId);
  let entity = new Sold(id);
  entity.buyer = event.params.buyer;
  entity.fee = event.params.fee;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.list = id;
  entity.save();

  let listEntity = List.load(id);
  if (listEntity != null) {
    listEntity.filledTxHash = event.transaction.hash;
    listEntity.save();
  }
}

export function handleListingCancelled(event: ListingCancelledEvent): void {
  let id = listingIdToBytes(event.params.listingId);
  let listEntity = List.load(id);
  if (listEntity != null) {
    listEntity.cancelTxHash = event.transaction.hash;
    listEntity.save();
  }
}
