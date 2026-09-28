extends Node

const SAVE_PATH = "user://cocktail_save_"

func save_game(slot: int, data: Dictionary):
    var file = FileAccess.open(SAVE_PATH + str(slot) + ".json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()

func load_game(slot: int) -> Dictionary:
    var file = FileAccess.open(SAVE_PATH + str(slot) + ".json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        file.close()
        return data if data else {}
    return {}
