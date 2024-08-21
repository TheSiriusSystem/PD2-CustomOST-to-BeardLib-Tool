extends Label
## A UI component for displaying the application's version.
##
## A UI component for displaying the application's version. Its text should contain
## only one instance of placeholder text (e.g. "Version %s", "ver. %s").


func _ready() -> void:
	text %= ProjectSettings.get_setting("application/config/version", "x.x.x")
