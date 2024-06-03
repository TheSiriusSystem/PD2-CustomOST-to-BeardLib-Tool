class_name Constants
extends Object
## Stores globally-accessible enums and constants.


enum MessageType
{
	NOTICE, ## Represents a plain message.
	WARNING, ## Represents a cautionary message.
	ERROR, ## Represents an error message.
}

const DEFAULT_SETTINGS: Dictionary = { ## Default user settings. Path settings set to special paths are converted to OS paths.
	"application": {
		"output_location": "user://output",
		"open_output_on_convert": true,
	},
	"converter": {
		"inherit_volume_params": false,
	},
}
