class_name ShapeBase
extends Resource

const BASE_PARAMETERS = [
	{"name": "is_refractive", "type": TYPE_BOOL, "default": false},
	{"name": "refractive_index", "type": TYPE_FLOAT, "default": 1.5, "min": 1.0}
]

var property_values: Dictionary = {}
@export var material: Material
var node_3d: Node3D

func _init():
	_setup_parameters()
	resource_name = "ShapeBase"

func _setup_parameters() -> void:
	var all_params = BASE_PARAMETERS + get_shape_parameters()
	for param in all_params:
		property_values[param.name] = param.default

func set_node_3d(node: Node3D) -> void:
	node_3d = node

# Keep these as they're used by child shapes for SDF generation
func get_shape_id() -> String:
	return str(node_3d.get_instance_id()) if node_3d else "0"

func get_parameter_name(param_name: String) -> String:
	return "shape%s_%s" % [get_shape_id(), param_name]

# Virtual methods for shapes to implement
func get_shape_parameters() -> Array:
	return []

func get_sdf_function() -> String:
	push_error("Base class method called")
	return ""

func get_sdf_call() -> String:
	push_error("Base class method called")
	return ""
