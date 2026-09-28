extends Node
class_name SexShopInventory

var economy: SexEconomySystem
var toy_catalog: ToyInventory

var shop_items: Array[Dictionary] = []
var sold_items: Array[Dictionary] = []

signal item_purchased(item_name: String, price: float)
signal item_sold(item_name: String, price: float)

func _init(_economy: SexEconomySystem, _toy_catalog: ToyInventory):
    economy = _economy
    toy_catalog = _toy_catalog
    _stock_shop()

func _stock_shop():
    var catalog = toy_catalog.get_available_catalog()
    for item in catalog:
        if not item["owned"]:
            shop_items.append(item)

func buy_item(item_name: String) -> bool:
    for item in shop_items:
        if item["name"] == item_name:
            if economy.spend_money(item["cost"], "toy_purchase"):
                toy_catalog.purchase_toy(item_name)
                shop_items.erase(item)
                item_purchased.emit(item_name, item["cost"])
                return true
    return false

func sell_item(item_name: String) -> bool:
    for toy in toy_catalog.owned_toys:
        if toy["name"] == item_name:
            var sell_price = toy["cost"] * 0.5
            economy.add_money(sell_price, "toy_sale")
            toy_catalog.owned_toys.erase(toy)
            sold_items.append(toy)
            item_sold.emit(item_name, sell_price)
            return true
    return false

func get_available_items() -> Array:
    return shop_items
