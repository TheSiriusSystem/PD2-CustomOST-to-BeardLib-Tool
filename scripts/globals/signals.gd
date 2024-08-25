extends Node
## Stores globally-accessible signals.

signal print_to_console(messages: PackedStringArray, type: Constants.MessageType)
signal show_alert(message: String, type: Constants.MessageType)
