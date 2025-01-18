@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Register the RaymarchCamera node
	add_custom_type(
		"RaymarchCamera",
		"Camera3D",
		preload("res://addons/Raymarching/management/Raymarching-camera.new.gd"),
		null  # You can add an icon later if you want
	)
	
	# Register the ShapeManager node
	add_custom_type(
		"ShapeManager",
		"Node3D",
		preload("res://addons/Raymarching/management/shape_manager.gd"),
		null
	)

func _exit_tree() -> void:
	# Clean up when plugin is disabled
	remove_custom_type("RaymarchCamera")
	remove_custom_type("ShapeManager")
