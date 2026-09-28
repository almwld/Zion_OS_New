extends Node
class_name DeepEmotionalAI

var body: CocktailBody

# --- Complex Emotions ---
var emotions: Dictionary = {
    "joy": 50.0, "sadness": 10.0, "anger": 5.0,
    "fear": 10.0, "surprise": 20.0, "disgust": 5.0,
    "trust": 50.0, "anticipation": 30.0,
    "love": 30.0, "lust": 20.0, "shame": 15.0,
    "pride": 40.0, "jealousy": 5.0, "gratitude": 40.0,
    "loneliness": 20.0, "hope": 60.0, "despair": 5.0,
    "ecstasy": 0.0, "boredom": 15.0, "curiosity": 50.0
}

var mood_history: Array[Dictionary] = []
var emotional_memory: Array[Dictionary] = []
var current_dominant_emotion: String = "neutral"
var emotional_stability: float = 0.7

# --- Relationship Dynamics ---
var attachment_style: String = "secure"
var love_languages: Array[String] = ["physical_touch", "words_of_affirmation"]
var trust_issues: float = 0.3
var commitment_phobia: float = 0.1

# --- Emotional Triggers ---
var triggers: Dictionary = {
    "being_ignored": {"anger": 20, "sadness": 15},
    "being_praised": {"joy": 15, "pride": 10},
    "being_insulted": {"anger": 25, "shame": 20},
    "partner_orgasm": {"joy": 20, "lust": 15, "pride": 10},
    "rejection": {"sadness": 30, "shame": 25},
    "intimacy": {"love": 20, "trust": 15},
    "cheating": {"anger": 50, "jealousy": 60, "sadness": 40}
}

signal emotion_changed(emotion: String, value: float)
signal mood_swing(old_mood: String, new_mood: String)
signal emotional_breakdown()
signal emotional_breakthrough()

func _init(_body: CocktailBody):
    body = _body
    _determine_attachment_style()

func _determine_attachment_style():
    var styles = ["secure", "anxious", "avoidant", "fearful"]
    attachment_style = styles[randi() % styles.size()]

func _process(delta):
    _decay_emotions(delta)
    _update_dominant_emotion()
    _process_emotional_memory(delta)

func _decay_emotions(delta):
    for emotion in emotions:
        emotions[emotion] = lerp(emotions[emotion], 30.0, delta * 0.1 * emotional_stability)

func _update_dominant_emotion():
    var max_val = 0.0
    var dominant = "neutral"
    for emotion in emotions:
        if emotions[emotion] > max_val:
            max_val = emotions[emotion]
            dominant = emotion
    if dominant != current_dominant_emotion:
        var old = current_dominant_emotion
        current_dominant_emotion = dominant
        mood_swing.emit(old, dominant)

func trigger_emotion(event: String):
    if triggers.has(event):
        for emotion in triggers[event]:
            emotions[emotion] = min(100, emotions[emotion] + triggers[event][emotion])
            emotion_changed.emit(emotion, emotions[emotion])
    emotional_memory.append({"event": event, "time": Time.get_ticks_msec()})

func _process_emotional_memory(delta):
    pass

func get_emotional_state() -> String:
    return current_dominant_emotion

func get_mood_label() -> String:
    match current_dominant_emotion:
        "joy": return "Happy"
        "sadness": return "Sad"
        "anger": return "Angry"
        "fear": return "Anxious"
        "love": return "Loving"
        "lust": return "Horny"
        "jealousy": return "Jealous"
        _: return "Neutral"
