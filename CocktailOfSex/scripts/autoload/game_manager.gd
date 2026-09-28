extends Node

enum GameMode { FREE_ROAM, SEX_SCENE, EDITOR, MENU }
var current_mode: GameMode = GameMode.FREE_ROAM
var player_body = null

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

func start_sex_scene(actors):
    if current_mode == GameMode.SEX_SCENE: return
    current_mode = GameMode.SEX_SCENE

func end_sex_scene():
    if current_mode == GameMode.SEX_SCENE:
        current_mode = GameMode.FREE_ROAM
