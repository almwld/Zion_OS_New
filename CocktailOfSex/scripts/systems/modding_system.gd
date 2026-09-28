extends Node
class_name ModdingSystem

var installed_mods: Array[Dictionary] = []
var mod_directory: String = "user://mods/"

signal mod_installed(mod_name: String)
signal mod_loaded(mod_name: String)

func _ready():
    _load_installed_mods()

func _load_installed_mods():
    var dir = DirAccess.open(mod_directory)
    if dir:
        dir.list_dir_begin()
        var file = dir.get_next()
        while file != "":
            if file.ends_with(".pck"):
                var mod = {"name": file, "loaded": false}
                installed_mods.append(mod)
                mod_loaded.emit(file)
            file = dir.get_next()

func install_mod(mod_path: String):
    var file_name = mod_path.get_file()
    DirAccess.copy_absolute(mod_path, mod_directory + file_name)
    mod_installed.emit(file_name)
