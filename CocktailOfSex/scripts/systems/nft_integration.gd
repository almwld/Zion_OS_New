extends Node
class_name NFTIntegration

var owned_nfts: Array[Dictionary] = []
var wallet_address: String = ""
var blockchain_connected: bool = false

signal nft_minted(nft: Dictionary)
signal nft_sold(nft: Dictionary, price: float)
signal wallet_connected(address: String)

func connect_wallet(address: String):
    wallet_address = address
    blockchain_connected = true
    wallet_connected.emit(address)

func mint_nft(item_name: String, item_data: Dictionary, rarity: String = "common") -> Dictionary:
    var nft = {
        "id": str(randi() % 999999).pad_zeros(6),
        "name": item_name,
        "data": item_data,
        "rarity": rarity,
        "mint_time": Time.get_ticks_msec(),
        "owner": wallet_address
    }
    owned_nfts.append(nft)
    nft_minted.emit(nft)
    return nft

func sell_nft(nft_id: String, price: float) -> bool:
    for nft in owned_nfts:
        if nft["id"] == nft_id:
            owned_nfts.erase(nft)
            nft_sold.emit(nft, price)
            return true
    return false

func get_nft_collection() -> Array:
    return owned_nfts
