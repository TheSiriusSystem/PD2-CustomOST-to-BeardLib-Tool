class_name Constants
extends Object
## Stores globally-accessible enums and constants.

enum MessageType
{
	NOTICE, ## Represents a plain message.
	WARNING, ## Represents a cautionary message.
	ERROR, ## Represents an error message.
}

## Default user settings. Any setting that is a string and ends with "location" is
## a path setting; these are converted to OS paths if set to special paths (e.g.
## [code]"userdata_location": "user://"[/code]).
const DEFAULT_SETTINGS: Dictionary = {
	"application": {
		"output_location": "user://output",
		"open_output_on_convert": true,
	},
	"converter": {
		"inherit_volume_params": false,
	},
}

## ...
## [codeblock]
## var dialog: FileDialog = FileDialog.new()
## dialog.size = Constants.FILE_DIALOG_SIZE
## add_child(dialog)
##
## var button: Button = Button.new()
## button.pressed.connect(dialog.popup_centered.bind(Constants.FILE_DIALOG_SIZE))
## add_child(button)
## [/codeblock]
const FILE_DIALOG_SIZE: Vector2i = Vector2i(540, 350)
