extends Node

var relationships: Dictionary = {}

func _ready():
    pass

func modify_relationship(subject: String, target: String, aspect: String, amount: float):
    if relationships.has(subject) and relationships[subject].has(target):
        relationships[subject][target][aspect] = clamp(relationships[subject][target][aspect] + amount, -100.0, 100.0)

func interact(body1, body2, action: String):
    match action:
        "touch":
            modify_relationship(body1.body_name, body2.body_name, "love", 0.5)
            modify_relationship(body1.body_name, body2.body_name, "lust", 1.0)
        "kiss":
            modify_relationship(body1.body_name, body2.body_name, "love", 2.0)
