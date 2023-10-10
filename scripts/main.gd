extends CanvasLayer

const OUTPUT_FOLDERS: PoolStringArray = PoolStringArray([
	"/sounds",
	"/loc",
])
const TRACK_EXTENSIONS: PoolStringArray = PoolStringArray([
	"movie",
	"ogg",
])

var track_info setget _on_track_info_set

onready var track_selection: Label = $TrackSelection
onready var convert_button: Button = $Buttons/ConvertTrack
onready var ignore_volume_params_setting: CheckButton = $Settings/IgnoreVolumeParams
onready var open_output_on_convert_setting: CheckButton = $Settings/OpenOutputOnConvert
onready var open_track_dialog: FileDialog = $Dialogs/OpenTrack
onready var alert_dialog: AcceptDialog = $Dialogs/Alert

func _ready() -> void:
	ensure_output_structure()

func show_alert(message: String, title: String = "Error") -> void:
	alert_dialog.popup_centered()
	alert_dialog.window_title = title
	alert_dialog.dialog_text = message

func ensure_output_structure() -> void:
	var dir: Directory = Directory.new()
	for folder in OUTPUT_FOLDERS:
		dir.make_dir_recursive(get_output_path() + folder)

func delete_files_in_folder(folder_path: String) -> void:
	var dir: Directory = Directory.new()
	if dir.open(folder_path) == OK:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var file_path: String = folder_path + "/" + file_name
				if dir.current_is_dir():
					delete_files_in_folder(file_path)
				else:
					dir.remove(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func get_track_name() -> String:
	return track_info.name if is_dict_key_valid(track_info, "name", TYPE_STRING) else "My music name"

func make_track_event(event_name: String, event_key: String) -> String:
	if is_dict_key_valid(track_info, "events", TYPE_DICTIONARY) and is_dict_key_valid(track_info.events, event_key, TYPE_DICTIONARY):
		var line: String = "		<event name=\"" + event_name + "\" source=\"" + (track_info.events[event_key].file if is_dict_key_valid(track_info.events[event_key], "file", TYPE_STRING) else event_key + "." + TRACK_EXTENSIONS[1]) + "\""
		if is_dict_key_valid(track_info.events[event_key], "start_file", TYPE_STRING):
			line += " start_source=\"" + track_info.events[event_key].start_file + "\""
		if is_dict_key_valid(track_info.events[event_key], "alt", TYPE_STRING):
			line += " alt_source=\"" + track_info.events[event_key].alt + "\""
		if is_dict_key_valid(track_info.events[event_key], "alt_chance", TYPE_REAL):
			line += " alt_chance=\"" + String(track_info.events[event_key].alt_chance) + "\""
		if not ignore_volume_params_setting.pressed and is_dict_key_valid(track_info.events[event_key], "volume", TYPE_REAL):
			line += " volume=\"" + String(track_info.events[event_key].volume) + "\""
		line += "/>"
		return line
	return "		<event name=\"" + event_name + "\" source=\"" + event_key + "." + TRACK_EXTENSIONS[1] + "\"/>"

func is_dict_key_valid(dict: Dictionary, key: String, type: int) -> bool:
	if dict.has(key) and typeof(dict[key]) == type:
		return true
	return false

func get_output_path() -> String:
	return OS.get_executable_path().get_base_dir() + "/output" if OS.has_feature("standalone") else ProjectSettings.globalize_path("res://") + ".output"

func _on_select_track_data_pressed() -> void:
	open_track_dialog.popup_centered()

func _on_convert_track_pressed() -> void:
	ensure_output_structure()
	delete_files_in_folder(get_output_path())
	
	var file: File = File.new()
	file.open(get_output_path() + "/main.xml", File.WRITE)
	file.store_line("<table name=\"" + track_info.id + "\">")
	file.store_line("	<Localization directory=\"loc\" default=\"en.txt\"/>")
	file.store_line("	<HeistMusic id=\"" + track_info.id + "\"" + (" volume=\"" + String(track_info.volume) + "\"" if not ignore_volume_params_setting.pressed and is_dict_key_valid(track_info, "volume", TYPE_REAL) else "") + " directory=\"sounds\">")
	file.store_line(make_track_event("setup", "setup"))
	file.store_line(make_track_event("anticipation", "buildup"))
	file.store_line(make_track_event("assault", "assault"))
	file.store_line(make_track_event("control", "control"))
	file.store_line("	</HeistMusic>")
	file.store_string("</table>")
	file.open(get_output_path() + OUTPUT_FOLDERS[1] + "/en.txt", File.WRITE)
	file.store_line("{")
	file.store_line("	 \"menu_jukebox_" + track_info.id + "\": \"" + get_track_name() + "\",")
	file.store_line("	 \"menu_jukebox_screen_" + track_info.id + "\": \"" + get_track_name() + "\"")
	file.store_string("}")
	file.close()
	
	var dir: Directory = Directory.new()
	var failed_copies: int = 0
	if dir.open(track_info.working_dir) == OK:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and TRACK_EXTENSIONS.has(file_name.get_extension()):
				if dir.copy(track_info.working_dir + "/" + file_name, get_output_path() + OUTPUT_FOLDERS[0] + "/" + file_name.get_file()) != OK:
					failed_copies += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if failed_copies > 0:
		show_alert("Failed to copy " + String(failed_copies) + " file(s) to the \"output\" folder.", "Warning")
	
	if open_output_on_convert_setting.pressed:
		OS.shell_open(get_output_path())

func _on_file_selected(path: String) -> void:
	var file: File = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		if is_dict_key_valid(data, "id", TYPE_STRING):
			data.working_dir = path.get_base_dir()
			if is_dict_key_valid(data, "volume", TYPE_REAL):
				data.volume = clamp(data.volume, 0.0, 1.0)
			else:
				data.erase("volume")
			data.erase("fade_duration")
			if is_dict_key_valid(data, "events", TYPE_DICTIONARY):
				for event in data.events.values():
					event.erase("fade_in")
					event.erase("fade_out")
			
			self.track_info = data.duplicate(true)
		else:
			show_alert("Selected file does not contain a valid ID. It should be a string.")
	else:
		show_alert("Selected file is not a valid JSON.")
	file.close()

func _on_track_info_set(new_value) -> void:
	track_info = new_value
	if typeof(new_value) == TYPE_DICTIONARY and is_dict_key_valid(track_info, "id", TYPE_STRING):
		track_selection.text = "Selected track: " + get_track_name() + " (" + new_value.id + ")"
		convert_button.disabled = false
	else:
		track_selection.text = "No track selected."
		convert_button.disabled = true
