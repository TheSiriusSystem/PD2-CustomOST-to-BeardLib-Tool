extends CanvasLayer
## Manages the application's main loop.


const OUTPUT_SUBFOLDER_PATH_SOUNDS: String = "sounds"
const OUTPUT_SUBFOLDER_PATH_LOCALIZATION: String = "loc"
const DEFAULT_TRACK_NAME: String = "My music name"
const RECOGNIZED_TRACK_EXTENSIONS: PackedStringArray = [
	"movie", # Natively supported by the Diesel engine.
	"ogg", # Support implemented by SuperBLT's XAudio API.
]
const TRACK_EVENT_MAP: Dictionary = {
	"setup": "setup",
	"buildup": "anticipation",
	"assault": "assault",
	"control": "control",
}
const UNREMOVABLE_FILE_NAMES: PackedStringArray = [
	".",
	"..",
]


func _ready() -> void:
	Signals.print_to_console.connect(func(messages: PackedStringArray, type: Constants.MessageType) -> void:
		var final_message: String
		for index in messages.size():
			if index == 0:
				final_message += "[%s] " % Time.get_datetime_string_from_system(false, true)
			else:
				final_message += " "
			final_message += messages[index]
		match type:
			Constants.MessageType.NOTICE:
				print(final_message)
			Constants.MessageType.WARNING:
				push_warning(final_message)
			Constants.MessageType.ERROR:
				push_error(final_message)
	)
	
	_ensure_output_structure()
	
	if not Data.settings_file_path.begins_with("user://"):
		Signals.print_to_console.emit(["Running in self-contained mode"], Constants.MessageType.NOTICE)
	if Data.unknown_sections > 0:
		Signals.print_to_console.emit(["%s unknown section(s) removed from settings" % Data.unknown_sections], Constants.MessageType.WARNING)
	if Data.unknown_section_keys > 0:
		Signals.print_to_console.emit(["%s unknown section key(s) removed from settings" % Data.unknown_section_keys], Constants.MessageType.WARNING)
	if Data.invalid_section_keys > 0:
		Signals.print_to_console.emit(["%s section key(s) of unexpected types found in settings" % Data.invalid_section_keys, "(invalid section keys are ignored, don't worry)"], Constants.MessageType.NOTICE)


func _ensure_output_structure() -> void:
	DirAccess.make_dir_recursive_absolute(_get_output_path(OUTPUT_SUBFOLDER_PATH_SOUNDS))
	DirAccess.make_dir_recursive_absolute(_get_output_path(OUTPUT_SUBFOLDER_PATH_LOCALIZATION))


func _clear_dir(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not UNREMOVABLE_FILE_NAMES.has(file_name):
				var file_path: String = "%s/%s" % [dir_path, file_name]
				if dir.current_is_dir():
					_clear_dir(file_path)
				else:
					dir.remove(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()


func _get_output_path(nested_path: String = "") -> String:
	var path: String = Data.settings.application.output_location
	if not nested_path.is_empty():
		path += "/%s" % nested_path
	return path


func _open_file_for_writing(path: String) -> Variant:
	var file = FileAccess.open(_get_output_path(path), FileAccess.WRITE)
	if not file:
		Signals.show_alert.emit("Could not write %s to output.\nCode: %s" % [path.get_file(), FileAccess.get_open_error()], Constants.MessageType.ERROR)
	return file


func _add_event_param_string(event_data: Dictionary, cost_event_name: String, bl_event_name: String, type: Variant.Type) -> String:
	if Utils.is_dict_key_valid(event_data, cost_event_name, type):
		return " %s=\"%s\"" % [bl_event_name, event_data[cost_event_name]]
	return ""


func _on_track_definition_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		Signals.show_alert.emit("Could not read selected file.\nCode: %s" % FileAccess.get_open_error(), Constants.MessageType.ERROR)
		return
	
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		Signals.show_alert.emit("Selected file is not a valid JSON.", Constants.MessageType.ERROR)
		return
	
	if not Utils.is_dict_key_valid(data, "id", TYPE_STRING):
		data.id = path.get_base_dir().get_file()
		Signals.print_to_console.emit(["Key \"id\" not found in track, inferring id to be the name", "of the folder it's in"], Constants.MessageType.WARNING)
	
	var was_events_empty: bool = false
	if not Utils.is_dict_key_valid(data, "events", TYPE_DICTIONARY):
		Signals.print_to_console.emit(["Key \"events\" not found in track, initializing defaults"], Constants.MessageType.WARNING)
		was_events_empty = true
		data.events = {}
	for cost_event_name in TRACK_EVENT_MAP.keys():
		if not Utils.is_dict_key_valid(data.events, cost_event_name, TYPE_DICTIONARY):
			if not was_events_empty:
				Signals.print_to_console.emit(["Key \"%s\" not found in track.events, initializing" % cost_event_name, "defaults"], Constants.MessageType.WARNING)
			data.events[cost_event_name] = {
				"file": "%s%s" % [cost_event_name, RECOGNIZED_TRACK_EXTENSIONS[1]]
			}
	
	_ensure_output_structure()
	_clear_dir(_get_output_path())
	Signals.print_to_console.emit(["Cleared output"], Constants.MessageType.NOTICE)
	
	file = _open_file_for_writing("main.xml")
	if not file:
		return
	Signals.print_to_console.emit(["Converting %s parameters" % data.id], Constants.MessageType.NOTICE)
	file.store_line("<table name=\"%s\">" % data.id)
	file.store_line("	<Localization directory=\"%s\" default=\"en.txt\"/>" % OUTPUT_SUBFOLDER_PATH_LOCALIZATION)
	file.store_line("	<HeistMusic id=\"%s\" directory=\"sounds\">" % data.id)
	for cost_event_name in TRACK_EVENT_MAP.keys():
		var bl_event_name: String = TRACK_EVENT_MAP[cost_event_name]
		var event_data: Dictionary = data.events[cost_event_name]
		var line: String = "		<event name=\"%s\" source=\"%s\"" % [bl_event_name, event_data.file]
		
		line += _add_event_param_string(event_data, "start_file", "start_source", TYPE_STRING)
		line += _add_event_param_string(event_data, "alt", "alt_source", TYPE_STRING)
		line += _add_event_param_string(event_data, "alt_start", "alt_start_source", TYPE_STRING)
		line += _add_event_param_string(event_data, "alt_chance", "alt_chance", TYPE_FLOAT)
		if Data.settings.converter.inherit_volume_params:
			line += _add_event_param_string(event_data, "volume", "volume", TYPE_FLOAT)
		line += "/>"
		file.store_line(line)
	file.store_line("	</HeistMusic>")
	file.store_string("</table>")
	
	file = _open_file_for_writing("%s/en.txt" % OUTPUT_SUBFOLDER_PATH_LOCALIZATION)
	if not file:
		return
	Signals.print_to_console.emit(["Creating %s localization file" % data.id], Constants.MessageType.NOTICE)
	var track_name: String = Utils.get_dict_key(data, "name", TYPE_STRING, DEFAULT_TRACK_NAME)
	file.store_string(JSON.stringify({
		"menu_jukebox_%s" % data.id: track_name,
		"menu_jukebox_screen_%s" % data.id: track_name
	}, "\t"))
	file.close()
	
	var audio_dir_path: String = path.get_base_dir()
	var dir: DirAccess = DirAccess.open(audio_dir_path)
	if not dir:
		Signals.show_alert.emit("Could not open working directory.\nCode: %s" % dir.get_open_error(), Constants.MessageType.ERROR)
		return
	var failed_copies: int = 0
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and RECOGNIZED_TRACK_EXTENSIONS.has(file_name.get_extension()):
			if dir.copy("%s/%s" % [audio_dir_path, file_name], "%s/%s" % [_get_output_path(OUTPUT_NESTED_PATH_SOUNDS), file_name.get_file()]) != OK:
				failed_copies += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	if failed_copies > 0:
		Signals.print_to_console.emit(["%s file(s) could not be copied to output" % failed_copies], Constants.MessageType.WARNING)
	
	file.close()
	if not Data.settings.application.open_output_on_convert:
		Signals.show_alert.emit("Successfully converted track definition.\nThe files can be found in output.", Constants.MessageType.NOTICE)
	else:
		OS.shell_open(_get_output_path())
	Signals.print_to_console.emit(["Finished converting track definition"], Constants.MessageType.NOTICE)


func _on_open_output_pressed() -> void:
	OS.shell_open(Data.settings.application.output_location)
