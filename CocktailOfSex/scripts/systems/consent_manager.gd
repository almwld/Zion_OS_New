extends Node
class_name ConsentManager

enum ConsentLevel { NONE, HESITANT, WILLING, ENTHUSIASTIC, SAFE_WORD }
var current_level: ConsentLevel = ConsentLevel.NONE
var safe_word: String = "RED"
var safe_word_used: bool = false

signal consent_changed(level: ConsentLevel)
signal safe_word_triggered()

func _init(sw: String = "RED"):
    safe_word = sw

func set_consent(level: ConsentLevel):
    current_level = level
    consent_changed.emit(current_level)

func can_proceed() -> bool:
    return current_level in [ConsentLevel.WILLING, ConsentLevel.ENTHUSIASTIC]

func trigger_safe_word():
    current_level = ConsentLevel.SAFE_WORD
    safe_word_used = true
    safe_word_triggered.emit()

func reset():
    current_level = ConsentLevel.NONE
    safe_word_used = false
