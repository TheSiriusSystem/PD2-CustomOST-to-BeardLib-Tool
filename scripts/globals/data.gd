extends Node
## Handles saving and loading user settings.


const RECOGNIZED_SELF_CONTAINED_MODE_FILE_NAMES: PackedStringArray = [
	"_sc_",
	"._sc_",
]

var settings: Dictionary = Constants.DEFAULT_SETTINGS.duplicate(true)
var settings_file_path: String = "user://"
var removed_sections: int = 0
var removed_section_keys: int = 0
var invalid_section_keys: int = 0

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	if not OS.has_feature("editor"):
		var application_dir_path: String = "%s/" % OS.get_executable_path().get_base_dir()
		for file_name in RECOGNIZED_SELF_CONTAINED_MODE_FILE_NAMES:
			if FileAccess.file_exists(application_dir_path + file_name):
				settings_file_path = application_dir_path
				break
	settings_file_path += "settings.cfg"
	
	for section in settings.keys():
		var section_keys: Dictionary = settings[section]
		for key in section_keys.keys():
			if typeof(section_keys[key]) == TYPE_STRING and (section_keys[key].begins_with("res://") or section_keys[key].begins_with("user://")):
				section_keys[key] = ProjectSettings.globalize_path(section_keys[key])
	
	if _config.load(settings_file_path) == OK:
		# Unknown sections/section keys are removed so the settings file looks neater.
		# Section keys with unexpected types are not loaded on startup.
		for section in _config.get_sections():
			if settings.has(section):
				var section_keys: Dictionary = settings[section]
				for key in _config.get_section_keys(section):
					if section_keys.has(key):
						var value_type: Variant.Type = typeof(Constants.DEFAULT_SETTINGS[section][key]) as Variant.Type
						var value = _config.get_value(section, key)
						if typeof(value) == value_type:
							section_keys[key] = value
						else:
							invalid_section_keys += 1
					else:
						_config.set_value(section, key, null)
						removed_section_keys += 1
			else:
				_config.erase_section(section)
				removed_sections += 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for section in settings.keys():
			var section_keys: Dictionary = settings[section]
			for key in section_keys.keys():
				_config.set_value(section, key, section_keys[key])
		_config.save(settings_file_path)
