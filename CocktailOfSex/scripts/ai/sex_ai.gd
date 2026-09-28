extends Node
class_name SexAI

enum Mood { SHY, NEUTRAL, HORNY, DOMINANT, SUBMISSIVE, LOVING, ANGRY }
enum Action { MOAN, BEG, PRAISE, DEMAND, CRY, LAUGH, WHISPER, SCREAM }

var current_mood: Mood = Mood.NEUTRAL
var arousal: float = 0.0
var body: CocktailBody

signal dialogue(text: String, type: Action)
signal mood_changed(mood: Mood)

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    _update_mood()
    if randf() < body.arousal * body.personality["vocalness"] * delta * 0.1:
        var bank = ["آه...", "أكثر...", "هناك...", "نعم!", "لا تتوقف...", "أعمق...", "أسرع..."]
        var text = bank[randi() % bank.size()]
        dialogue.emit(text, Action.MOAN)

func _update_mood():
    var nm = Mood.NEUTRAL
    if body.arousal > 80:
        nm = Mood.HORNY if body.personality["dominance"] < 0.5 else Mood.DOMINANT
    elif body.arousal > 40:
        nm = Mood.SHY if body.personality["shyness"] > 0.6 else Mood.NEUTRAL
    if nm != current_mood:
        current_mood = nm
        mood_changed.emit(current_mood)
