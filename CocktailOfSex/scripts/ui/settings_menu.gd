extends Control
class_name SettingsMenu

@onready var master_vol: HSlider = $Panel/MasterVol
@onready var sfx_vol: HSlider = $Panel/SFXVol
@onready var music_vol: HSlider = $Panel/MusicVol
@onready var moan_vol: HSlider = $Panel/MoanVol
@onready var fullscreen_btn: CheckButton = $Panel/Fullscreen
@onready var vsync_btn: CheckButton = $Panel/VSync
@onready var resolution_opt: OptionButton = $Panel/Resolution

func _ready():
    master_vol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
    sfx_vol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
    music_vol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
    fullscreen_btn.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    vsync_btn.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
    master_vol.value_changed.connect(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), v))
    sfx_vol.value_changed.connect(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), v))
    music_vol.value_changed.connect(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), v))
    fullscreen_btn.toggled.connect(func(b): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if b else DisplayServer.WINDOW_MODE_WINDOWED))
    vsync_btn.toggled.connect(func(b): DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if b else DisplayServer.VSYNC_DISABLED))
    resolution_opt.add_item("1920x1080")
    resolution_opt.add_item("2560x1440")
    resolution_opt.add_item("3840x2160")
    resolution_opt.item_selected.connect(func(i):
        match i:
            0: get_window().size = Vector2i(1920, 1080)
            1: get_window().size = Vector2i(2560, 1440)
            2: get_window().size = Vector2i(3840, 2160)
    )
