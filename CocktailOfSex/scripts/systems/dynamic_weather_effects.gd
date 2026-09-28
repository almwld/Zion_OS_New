extends Node
class_name DynamicWeatherEffects

var current_weather: String = "clear"
var weather_intensity: float = 0.0
var weather_transition_speed: float = 0.5

var rain_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var fog_volume: FogVolume
var lightning_timer: float = 0.0
var thunder_sounds: Array[AudioStream] = []

var weather_effects: Dictionary = {
    "clear": {
        "light_color": Color(1.0, 0.95, 0.8),
        "light_energy": 1.0,
        "ambient_color": Color(0.3, 0.4, 0.6),
        "fog_density": 0.0,
        "particles_active": false,
        "arousal_modifier": 1.0
    },
    "rain": {
        "light_color": Color(0.5, 0.6, 0.8),
        "light_energy": 0.5,
        "ambient_color": Color(0.2, 0.2, 0.3),
        "fog_density": 0.02,
        "particles_active": true,
        "arousal_modifier": 1.4
    },
    "storm": {
        "light_color": Color(0.3, 0.3, 0.5),
        "light_energy": 0.3,
        "ambient_color": Color(0.1, 0.1, 0.2),
        "fog_density": 0.04,
        "particles_active": true,
        "arousal_modifier": 1.8
    },
    "snow": {
        "light_color": Color(0.9, 0.9, 1.0),
        "light_energy": 0.7,
        "ambient_color": Color(0.4, 0.5, 0.7),
        "fog_density": 0.03,
        "particles_active": true,
        "arousal_modifier": 0.9
    },
    "foggy": {
        "light_color": Color(0.7, 0.7, 0.7),
        "light_energy": 0.4,
        "ambient_color": Color(0.3, 0.3, 0.3),
        "fog_density": 0.08,
        "particles_active": false,
        "arousal_modifier": 1.2
    },
    "heatwave": {
        "light_color": Color(1.0, 0.8, 0.5),
        "light_energy": 1.3,
        "ambient_color": Color(0.5, 0.4, 0.2),
        "fog_density": 0.01,
        "particles_active": false,
        "arousal_modifier": 1.3
    }
}

signal weather_changed(weather: String, intensity: float)
signal lightning_struck(position: Vector3)

func _ready():
    _setup_particles()
    _setup_fog()
    _load_thunder_sounds()

func _setup_particles():
    rain_particles = GPUParticles3D.new()
    rain_particles.name = "RainParticles"
    rain_particles.amount = 5000
    rain_particles.lifetime = 1.0
    rain_particles.emitting = false
    add_child(rain_particles)

    snow_particles = GPUParticles3D.new()
    snow_particles.name = "SnowParticles"
    snow_particles.amount = 3000
    snow_particles.lifetime = 3.0
    snow_particles.emitting = false
    add_child(snow_particles)

func _setup_fog():
    fog_volume = FogVolume.new()
    fog_volume.name = "WeatherFog"
    add_child(fog_volume)

func _load_thunder_sounds():
    for i in range(5):
        var path = "res://assets/audio/weather/thunder_" + str(i) + ".ogg"
        if ResourceLoader.exists(path):
            thunder_sounds.append(load(path))

func set_weather(weather: String):
    if not weather_effects.has(weather): return
    current_weather = weather
    var effects = weather_effects[weather]
    var light = get_viewport().get_camera_3d()
    if light:
        pass
    rain_particles.emitting = (weather in ["rain", "storm"])
    snow_particles.emitting = (weather == "snow")
    weather_changed.emit(weather, weather_intensity)

func _process(delta):
    if current_weather in ["rain", "storm", "snow"]:
        weather_intensity = lerp(weather_intensity, 1.0, delta * weather_transition_speed)
    else:
        weather_intensity = lerp(weather_intensity, 0.0, delta * weather_transition_speed)
    if current_weather == "storm":
        lightning_timer -= delta
        if lightning_timer <= 0:
            _trigger_lightning()

func _trigger_lightning():
    lightning_timer = randf_range(3.0, 15.0)
    var pos = Vector3(randf_range(-50, 50), randf_range(10, 30), randf_range(-50, 50))
    lightning_struck.emit(pos)
    if thunder_sounds.size() > 0:
        var player = AudioStreamPlayer.new()
        player.stream = thunder_sounds[randi() % thunder_sounds.size()]
        add_child(player)
        player.play()
        await get_tree().create_timer(3.0).timeout
        player.queue_free()

func get_arousal_modifier() -> float:
    if weather_effects.has(current_weather):
        return weather_effects[current_weather]["arousal_modifier"]
    return 1.0
