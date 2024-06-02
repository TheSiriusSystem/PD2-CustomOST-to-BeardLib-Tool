extends Label
## A UI component that displays the application's version.


func _ready() -> void:
	text = text % ProjectSettings.get_setting("application/config/version", "x.x.x")
