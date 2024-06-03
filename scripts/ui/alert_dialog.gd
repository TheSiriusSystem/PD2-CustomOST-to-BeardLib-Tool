extends AcceptDialog
## A dialog serving the same purpose as [AcceptDialog].
##
## This dialog is similar to [AcceptDialog], but it has centered dialog text and
## its title depends on the [enum Constants.MessageType] passed.
## [codeblock]
## Signals.show_alert.emit("Hello World!", Constants.MessageType.NOTICE)
## [/codeblock]


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
