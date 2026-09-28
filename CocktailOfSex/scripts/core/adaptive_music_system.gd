extends Node
class_name AdaptiveMusicSystem

# ============================================
# ADAPTIVE MUSIC SYSTEM
# Music layers that change with arousal
# ============================================

var body: CocktailBody

var music_layers: Dictionary = {
    "ambient": {"player": null, "volume": 0.0, "target_volume": 0.5},
    "rhythm": {"player": null, "volume": 0.0, "target_volume": 0.0},
    "bass": {"player": null, "volume": 0.0, "target_volume": 0.0},
    "melody": {"player": null, "volume": 0.0, "target_volume": 0.0},
    "vocals": {"player": null, "volume": 0.0, "target_volume": 0.0},
    "climax": {"player": null, "volume": 0.0, "target_volume": 0.0}
}

var current_bpm: float = 80.0
var target_bpm: float = 80.0

var moan_samples: Array[AudioStream] = []
var wet_sound_samples: Array[AudioStream] = []
var squirt_samples: Array[AudioStream] = []
var spank_samples: Array[AudioStream] = []
var kiss_samples: Array[AudioStream] = []

var moan_player_pool: Array[AudioStreamPlayer] = []
var sfx_player_pool: Array[AudioStreamPlayer] = []

func _init(_body: CocktailBody):
    body = _body

func _ready():
    _setup_layers()
    _setup_sfx_pool()
    _load_samples()

func _setup_layers():
    for layer_name in music_layers:
        var player = AudioStreamPlayer.new()
        player.bus = "Music"
        add_child(player)
        music_layers[layer_name]["player"] = player

func _setup_sfx_pool():
    for i in range(10):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        moan_player_pool.append(player)
    for i in range(15):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        sfx_player_pool.append(player)

func _load_samples():
    for i in range(20):
        var path = "res://assets/audio/moans/moan_" + str(i).pad_zeros(2) + ".ogg"
        if ResourceLoader.exists(path):
            moan_samples.append(load(path))
    for i in range(10):
        var path = "res://assets/audio/wet/wet_" + str(i).pad_zeros(2) + ".ogg"
        if ResourceLoader.exists(path):
            wet_sound_samples.append(load(path))

func _process(delta):
    _update_adaptive_layers(delta)
    _update_bpm(delta)

func _update_adaptive_layers(delta):
    var arousal = body.arousal
    if arousal < 20:
        music_layers["ambient"]["target_volume"] = 0.5
        music_layers["rhythm"]["target_volume"] = 0.0
        music_layers["bass"]["target_volume"] = 0.0
        music_layers["melody"]["target_volume"] = 0.0
        target_bpm = 70.0
    elif arousal < 40:
        music_layers["ambient"]["target_volume"] = 0.4
        music_layers["rhythm"]["target_volume"] = 0.3
        music_layers["bass"]["target_volume"] = 0.1
        music_layers["melody"]["target_volume"] = 0.0
        target_bpm = 85.0
    elif arousal < 60:
        music_layers["ambient"]["target_volume"] = 0.3
        music_layers["rhythm"]["target_volume"] = 0.5
        music_layers["bass"]["target_volume"] = 0.3
        music_layers["melody"]["target_volume"] = 0.2
        target_bpm = 100.0
    elif arousal < 80:
        music_layers["ambient"]["target_volume"] = 0.2
        music_layers["rhythm"]["target_volume"] = 0.6
        music_layers["bass"]["target_volume"] = 0.5
        music_layers["melody"]["target_volume"] = 0.4
        target_bpm = 120.0
    elif arousal < 95:
        music_layers["ambient"]["target_volume"] = 0.1
        music_layers["rhythm"]["target_volume"] = 0.7
        music_layers["bass"]["target_volume"] = 0.6
        music_layers["melody"]["target_volume"] = 0.6
        music_layers["climax"]["target_volume"] = 0.3
        target_bpm = 140.0
    else:
        music_layers["ambient"]["target_volume"] = 0.0
        music_layers["rhythm"]["target_volume"] = 0.8
        music_layers["bass"]["target_volume"] = 0.8
        music_layers["melody"]["target_volume"] = 0.8
        music_layers["climax"]["target_volume"] = 0.8
        target_bpm = 160.0

    for layer_name in music_layers:
        var layer = music_layers[layer_name]
        layer["volume"] = lerp(layer["volume"], layer["target_volume"], delta * 2.0)
        if layer["player"]:
            layer["player"].volume_db = linear_to_db(layer["volume"])

func _update_bpm(delta):
    current_bpm = lerp(current_bpm, target_bpm, delta * 3.0)

func play_random_moan(intensity: float):
    if moan_samples.size() == 0: return
    for player in moan_player_pool:
        if not player.playing:
            player.stream = moan_samples[randi() % moan_samples.size()]
            player.volume_db = linear_to_db(intensity)
            player.pitch_scale = randf_range(0.8, 1.2)
            player.play()
            return

func play_wet_sound(intensity: float):
    if wet_sound_samples.size() == 0: return
    for player in sfx_player_pool:
        if not player.playing:
            player.stream = wet_sound_samples[randi() % wet_sound_samples.size()]
            player.volume_db = linear_to_db(intensity)
            player.play()
            return

func trigger_climax_music():
    music_layers["climax"]["target_volume"] = 1.0
    target_bpm = 180.0
    await get_tree().create_timer(2.0).timeout
    for layer_name in music_layers:
        music_layers[layer_name]["target_volume"] = 0.0
    target_bpm = 60.0
