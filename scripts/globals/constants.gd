class_name Constants
extends Object
## Stores globally-accessible enums and constants.


enum AlertType
{
	SUCCESS,
	WARNING,
	ERROR,
}

const DEFAULT_SETTINGS: Dictionary = {
	"application": {
		"output_location": "user://output",
		"open_output_on_convert": true,
	},
	"converter": {
		"inherit_volume_params": false,
	},
}
