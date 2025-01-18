@tool
extends Node

@export var reload_nodes: bool = false : set = _reload_nodes

func _reload_nodes(value: bool) -> void:
	reload_nodes = false  # Reset the button
	if not value:  # Only trigger on "pressed" (true)
		return
		
	# Get the root node of the current scene
	var root = get_tree().get_edited_scene_root()
	if not root:
		return
		
	# Recursively find and reload nodes
	reload_node_recursive(root)

func reload_node_recursive(node: Node) -> void:
	# Skip if node doesn't exist
	if not is_instance_valid(node):
		return
		
	# Get the node's script
	var script = node.get_script()
	if script:
		# Store node data
		var parent = node.get_parent()
		var name = node.name
		var props = {}
		
		# Save all exportable properties
		for prop in node.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE:
				props[prop.name] = node.get(prop.name)
		
		# Remove old node
		node.queue_free()
		
		# Create new node
		var new_node = Node.new()
		new_node.set_script(script)
		new_node.name = name
		
		# Restore properties
		for prop_name in props:
			new_node.set(prop_name, props[prop_name])
			
		# Add to parent
		parent.add_child(new_node)
		new_node.owner = get_tree().get_edited_scene_root()
		
	# Process children
	for child in node.get_children():
		reload_node_recursive(child)
