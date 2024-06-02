extends VBoxContainer
## A UI component that allows management of user settings.


@export var _dialog_location: Node
@export var _section_separator_scene: PackedScene
@export var _location_item_scene: PackedScene

var _created_sections: int = 0


func _ready() -> void:
	for section in Constants.DEFAULT_SETTINGS.keys():
		var section_keys: Dictionary = Constants.DEFAULT_SETTINGS[section]
		if section_keys.size() == 0:
			continue
		
		var separator: VBoxContainer = _section_separator_scene.instantiate()
		if _created_sections == 0:
			separator.get_node("HSeparatorTop").visible = false
		separator.get_node("Label").text = section.capitalize()
		add_child(separator)
		
		for key in section_keys.keys():
			var setting_name: String = key.capitalize()
			
			if typeof(section_keys[key]) == TYPE_BOOL:
				var button: CheckButton = CheckButton.new()
				button.text = setting_name
				button.button_pressed = Data.settings[section][key]
				button.pressed.connect(func() -> void:
					_set_setting(section, key, button.button_pressed)
				)
				add_child(button)
			elif typeof(section_keys[key]) == TYPE_STRING:
				if key.ends_with("location"): # HACK: Assume that any section keys ending with "location" are path settings.
					var location_item: HBoxContainer = _location_item_scene.instantiate()
					
					var dialog: FileDialog = FileDialog.new()
					dialog.name = "Select%s" % setting_name.replace(" ", "")
					dialog.access = FileDialog.ACCESS_FILESYSTEM
					dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
					dialog.title = "Select a New %s" % setting_name
					dialog.size = Vector2i(480, 300)
					dialog.dir_selected.connect(func(dir: String) -> void:
						Utils.set_node_properties(location_item.get_node("Path"), {
							&"text": dir,
							&"tooltip_text": dir,
						})
						_set_setting(section, key, dir)
					)
					_dialog_location.add_child(dialog)
					
					location_item.get_node("Label").text = " %s" % setting_name
					Utils.set_node_properties(location_item.get_node("Path"), {
						&"text": Data.settings[section][key],
						&"tooltip_text": Data.settings[section][key],
					})
					location_item.get_node("Browse").pressed.connect(dialog.popup_centered)
					add_child(location_item)
				else:
					pass
		
		_created_sections += 1


func _set_setting(section: String, key: String, value) -> void:
	Data.settings[section][key] = value
	Signals.print_to_console.emit(["Set %s/%s to %s" % [section, key, value]], Constants.MessageType.NOTICE)
