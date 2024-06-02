extends VBoxContainer
## A UI component that displays messages in a vertical list. The maximum amount of
## messages is determined by how many children it has.


var _current_messages: Array[Dictionary]

@onready var _labels: Array[Node] = get_children()


func _ready() -> void:
	Signals.print_to_console.connect(func(messages: PackedStringArray, type: Constants.MessageType) -> void:
		for message in messages:
			_current_messages.push_back({
				"text": message,
				"type": type,
			})
			if _current_messages.size() > _labels.size():
				_current_messages.pop_front()
		
		for index in _labels.size():
			if index < _current_messages.size():
				_labels[index].text = _current_messages[index].text
				match _current_messages[index].type:
					Constants.MessageType.NOTICE:
						_labels[index].self_modulate = Color8(143, 171, 130)
					Constants.MessageType.WARNING:
						_labels[index].self_modulate = Color8(184, 156, 122)
					Constants.MessageType.ERROR:
						_labels[index].self_modulate = Color8(196, 89, 89)
			else:
				_labels[index].text = ""
	)
