extends AcceptDialog


@onready var _label: Label = $Label


func _ready() -> void:
	Signals.show_alert.connect(func(message: String, type: Constants.MessageType) -> void:
		match type:
			Constants.MessageType.NOTICE:
				title = "✔ Success ✔"
			Constants.MessageType.WARNING:
				title = "⚠ Warning ⚠"
			Constants.MessageType.ERROR:
				title = "❌ Error ❌"
		_label.text = message
		reset_size()
		popup_centered()
	)
