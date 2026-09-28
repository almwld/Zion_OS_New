extends Node
class_name BodyModificationSystem

var body: CocktailBody

var modifications: Dictionary = {
    "piercings": {
        "nipple_left": false,
        "nipple_right": false,
        "clitoris": false,
        "penis_head": false,
        "penis_shaft": false,
        "belly_button": false,
        "tongue": false,
        "lip": false,
        "nose": false,
        "eyebrow": false
    },
    "tattoos": [],
    "implants": {
        "breast": false,
        "butt": false,
        "lips": false,
        "penis": false
    },
    "surgeries": {
        "circumcision": false,
        "vaginoplasty": false,
        "phalloplasty": false,
        "breast_augmentation": false,
        "breast_reduction": false
    }
}

var piercing_arousal_bonus: float = 0.05
var implant_arousal_bonus: float = 0.1
var tattoo_attraction_bonus: float = 0.03

signal modification_applied(type: String, name: String)
signal modification_removed(type: String, name: String)

func _init(_body: CocktailBody):
    body = _body

func add_piercing(location: String):
    if modifications["piercings"].has(location):
        modifications["piercings"][location] = true
        body.zones[location] = body.zones.get(location, 0.5) + piercing_arousal_bonus
        modification_applied.emit("piercing", location)

func remove_piercing(location: String):
    if modifications["piercings"].has(location):
        modifications["piercings"][location] = false
        body.zones[location] = max(0.1, body.zones.get(location, 0.5) - piercing_arousal_bonus)
        modification_removed.emit("piercing", location)

func add_tattoo(design: String, location: String, size: String, color: String):
    var tattoo = {
        "design": design,
        "location": location,
        "size": size,
        "color": color,
        "date_applied": Time.get_ticks_msec()
    }
    modifications["tattoos"].append(tattoo)
    modification_applied.emit("tattoo", design)

func add_implant(type: String):
    if modifications["implants"].has(type):
        modifications["implants"][type] = true
        match type:
            "breast":
                body.breast_size = min(2.0, body.breast_size + 0.5)
                body.zones["nipples"] = body.zones.get("nipples", 0.5) + implant_arousal_bonus
            "butt":
                body.zones["anus_ring"] = body.zones.get("anus_ring", 0.5) + implant_arousal_bonus
            "penis":
                body.penis_length += 0.03
                body.penis_girth += 0.01
        modification_applied.emit("implant", type)

func perform_surgery(type: String):
    if modifications["surgeries"].has(type):
        modifications["surgeries"][type] = true
        match type:
            "circumcision":
                body.zones["penis_head"] = body.zones.get("penis_head", 0.5) + 0.2
            "breast_augmentation":
                body.breast_size = min(2.0, body.breast_size + 1.0)
            "breast_reduction":
                body.breast_size = max(0.1, body.breast_size - 0.5)
        modification_applied.emit("surgery", type)

func get_modification_report() -> Dictionary:
    return {
        "piercings": modifications["piercings"].duplicate(),
        "tattoos_count": modifications["tattoos"].size(),
        "implants": modifications["implants"].duplicate(),
        "surgeries": modifications["surgeries"].duplicate()
    }
