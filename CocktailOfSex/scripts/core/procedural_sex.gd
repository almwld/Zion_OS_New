extends Node
class_name ProceduralSex

var seed: int = 0

func _ready():
    randomize()
    seed = randi()

func generate_scene() -> Dictionary:
    seed(seed)
    var num = randi_range(2, 10)
    var locations = ["bedroom", "bathroom", "kitchen", "office", "beach", "spaceship", "dungeon", "forest", "pool", "church", "school", "hospital"]
    var all_pos = ["missionary", "doggy_style", "cowgirl", "anal", "blowjob", "cunnilingus", "sixty_nine", "double_penetration"]
    var all_acts = ["vaginal_sex", "anal_sex", "oral_sex", "fingering", "handjob", "tribbing", "rimming"]
    var pos = []
    for i in range(num / 2):
        pos.append(all_pos[randi() % all_pos.size()])
    var acts = []
    for i in range(num * 2):
        acts.append(all_acts[randi() % all_acts.size()])
    return {
        "participants": num,
        "location": locations[randi() % locations.size()],
        "positions": pos,
        "actions": acts,
        "seed": seed
    }
