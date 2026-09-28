extends Node
class_name AIPersonalityEngine

var body: CocktailBody

enum Mood { HAPPY, SAD, ANGRY, HORNY, NERVOUS, CONFIDENT, SHY, DOMINANT, SUBMISSIVE, NEUTRAL }
var current_mood: Mood = Mood.NEUTRAL
var mood_history: Array[Dictionary] = []
var arousal_threshold_high: float = 70.0
var arousal_threshold_low: float = 30.0

signal mood_changed(new_mood: Mood, old_mood: Mood)
signal personality_shift(trait: String, old_value: float, new_value: float)

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    _evaluate_mood()

func _evaluate_mood():
    var old = current_mood
    if body.arousal > arousal_threshold_high:
        if body.personality["dominance"] > 0.6:
            current_mood = Mood.DOMINANT
        elif body.personality["shyness"] > 0.6:
            current_mood = Mood.NERVOUS
        else:
            current_mood = Mood.HORNY
    elif body.arousal > arousal_threshold_low:
        if body.personality["shyness"] > 0.5:
            current_mood = Mood.SHY
        else:
            current_mood = Mood.CONFIDENT
    else:
        current_mood = Mood.NEUTRAL
    if old != current_mood:
        mood_history.append({"mood": current_mood, "time": Time.get_ticks_msec(), "arousal": body.arousal})
        mood_changed.emit(current_mood, old)

func adapt_personality():
    if mood_history.size() > 10:
        var horny_count = 0
        var dom_count = 0
        var sub_count = 0
        for entry in mood_history:
            match entry["mood"]:
                Mood.HORNY: horny_count += 1
                Mood.DOMINANT: dom_count += 1
                Mood.SUBMISSIVE: sub_count += 1
        if horny_count > 5:
            var old_libido = body.personality["libido"]
            body.personality["libido"] = min(1.0, body.personality["libido"] + 0.05)
            personality_shift.emit("libido", old_libido, body.personality["libido"])
        if dom_count > sub_count:
            var old_dom = body.personality["dominance"]
            body.personality["dominance"] = min(1.0, body.personality["dominance"] + 0.03)
            personality_shift.emit("dominance", old_dom, body.personality["dominance"])

func get_mood_string() -> String:
    match current_mood:
        Mood.HAPPY: return "Happy"
        Mood.SAD: return "Sad"
        Mood.ANGRY: return "Angry"
        Mood.HORNY: return "Horny"
        Mood.NERVOUS: return "Nervous"
        Mood.CONFIDENT: return "Confident"
        Mood.SHY: return "Shy"
        Mood.DOMINANT: return "Dominant"
        Mood.SUBMISSIVE: return "Submissive"
        Mood.NEUTRAL: return "Neutral"
    return "Unknown"

func get_arousal_state() -> String:
    if body.arousal > 80: return "Desperate"
    elif body.arousal > 60: return "Eager"
    elif body.arousal > 40: return "Aroused"
    elif body.arousal > 20: return "Interested"
    else: return "Calm"
