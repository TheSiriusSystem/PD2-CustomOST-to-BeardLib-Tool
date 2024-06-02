class_name Utils
extends Object
## Stores globally-accessible functions.


## Assigns the given values to the given properties for [param node].
## [codeblock]
## var node = Node2D.new()
## Utils.set_node_properties(node, {
##     &"global_scale": Vector2(8.0, 2.5),
##     &"rotation": 1.5,
## })
## print(node.global_scale) # Prints (8, 2.5)
## [/codeblock]
## [b]Note:[/b] In C#, properties must be in snake_case when referring to built-in
## Godot properties. Prefer using the names exposed in the [code]PropertyName[/code]
## class to avoid allocating a new [StringName] on each call.
static func set_node_properties(node: Node, properties: Dictionary) -> void:
	for property in properties.keys():
		node.set(property, properties[property])


## Returns [code]true[/code] if [param key] exists in [param dict] and its type
## matches [param type].
static func is_dict_key_valid(dict: Dictionary, key, type: Variant.Type) -> bool:
	return (dict.has(key) and typeof(dict[key]) == type)


## Returns [param key] if it exists in [param dict] and its type matches
## [param type]. Returns [param default] otherwise.
static func get_dict_key(dict: Dictionary, key, type: Variant.Type, default = null) -> Variant:
	return dict[key] if is_dict_key_valid(dict, key, type) else default
