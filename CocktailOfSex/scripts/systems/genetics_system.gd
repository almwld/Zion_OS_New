extends Node

var body = null
var genetics: Dictionary = {}
var genetic_mutations: Array = []
var family_tree: Dictionary = {"mother": null, "father": null, "siblings": [], "children": []}

signal child_born(child, parents: Array)

func _init(_body = null):
    body = _body
    genetics = {
        "hair_color": Color(randf(), randf(), randf()),
        "eye_color": Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8)),
        "height": randf_range(1.55, 1.95),
        "breast_size": randf_range(0.1, 1.0),
        "penis_length": randf_range(0.08, 0.25)
    }
