extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array = []

func _ready():
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    for i in range(10):
        var p = AudioStreamPlayer.new()
        add_child(p)
        sfx_players.append(p)

func play_music(stream):
    music_player.stream = stream
    music_player.play()

func play_sfx(stream, volume_db: float = 0.0):
    for p in sfx_players:
        if not p.playing:
            p.stream = stream
            p.volume_db = volume_db
            p.play()
            return
