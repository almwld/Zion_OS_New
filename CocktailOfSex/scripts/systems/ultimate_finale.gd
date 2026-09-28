extends Node

var finale_triggered: bool = false

signal finale_started(description: String)

func trigger_finale():
    finale_triggered = true
    finale_started.emit("The Great Finale has begun!")
