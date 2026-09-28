extends Node
class_name AIEmotionEngine

var body: CocktailBody

var emotions: Dictionary = {
    "joy": 50.0,
    "sadness": 10.0,
    "anger": 5.0,
    "fear": 10.0,
    "disgust": 5.0,
    "trust": 50.0,
    "anticipation": 30.0,
    "surprise": 20.0,
    "love": 30.0,
    "lust": 20.0,
    "shame": 15.0,
    "pride": 40.0
}

signal emotion_changed(emotion: String, value: float)

func _init(_body: CocktailBody):
    body = _body

func modify_emotion(emotion: String, amount: float):
    if emotions.has(emotion):
        emotions[emotion] = clamp(emotions[emotion] + amount, 0.0, 100.0)
        emotion_changed.emit(emotion, emotions[emotion])

func get_dominant_emotion() -> String:
    var best = ""
    var best_val = 0.0
    for e in emotions:
        if emotions[e] > best_val:
            best_val = emotions[e]
            best = e
    return best

func get_emotional_state() -> String:
    var dom = get_dominant_emotion()
    var val = emotions[dom]
    if val > 80: return "Overwhelming " + dom
    elif val > 60: return "Strong " + dom
    elif val > 40: return "Moderate " + dom
    elif val > 20: return "Slight " + dom
    else: return "Barely " + dom

func _process(delta):
    emotions["lust"] = lerp(emotions["lust"], body.arousal, delta * 0.1)
    if body.is_climaxing:
        emotions["joy"] = min(100, emotions["joy"] + delta * 10.0)
        emotions["lust"] = max(0, emotions["lust"] - delta * 20.0)
