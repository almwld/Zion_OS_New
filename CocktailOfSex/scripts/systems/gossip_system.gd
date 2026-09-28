extends Node

var rumors: Array = []

func spread_rumor(subject, topic: String):
    rumors.append({"subject": subject.body_name, "topic": topic, "time": Time.get_ticks_msec()})

func clear_old_rumors(max_age: float = 3600.0):
    var current = Time.get_ticks_msec()
    var to_remove = []
    for i in range(rumors.size()):
        if current - rumors[i]["time"] > max_age * 1000:
            to_remove.append(i)
    for i in to_remove:
        if i < rumors.size():
            rumors.remove_at(i)
