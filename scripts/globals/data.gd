extends Node
## Handles saving and loading user settings.


const SELF_CONTAINED_FILE_NAMES: PackedStringArray = [
	"._sc_",
	"_sc_",
]

var self_contained_mode: bool = false
var settings: Dictionary = Constants.DEFAULT_SETTINGS.duplicate(true)
var unknown_sections: int = 0
var unknown_section_keys: int = 0
var invalid_section_keys: int = 0

var _config: ConfigFile = ConfigFile.new()
var _settings_path: String = "%ssettings.cfg"


func _ready() -> void:
	for file_name in SELF_CONTAINED_FILE_NAMES:
		if FileAccess.file_exists(Utils.get_application_dir() + file_name):
			self_contained_mode = true
			break
	
	_settings_path = _settings_path % Utils.get_userdata_path()
	for section in settings.keys():
		var section_keys: Dictionary = settings[section]
		for key in section_keys.keys():
				section_keys[key] = ProjectSettings.globalize_path(section_keys[key])
			if typeof(section_keys[key]) == TYPE_STRING and Utils.is_path_setting(key):
	if _config.load(_settings_path) == OK:
		# Unknown sections/section keys are removed so the settings file looks cleaner.
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
						unknown_section_keys += 1
			else:
				_config.erase_section(section)
				unknown_sections += 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for section in settings.keys():
			var section_keys: Dictionary = settings[section]
			for key in section_keys.keys():
				_config.set_value(section, key, section_keys[key])
		_config.save(_settings_path)
