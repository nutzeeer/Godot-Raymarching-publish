class_name ShapeBase
extends Resource

const BASE_PARAMETERS = [
#{Parameters applied to all shapes go here}
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

func get_transform_matrix() -> Transform3D:
	return node_3d.transform if node_3d else Transform3D.IDENTITY

func get_shape_id() -> String:
	return str(node_3d.get_instance_id()) if node_3d else "0"

func get_parameter_name(param_name: String) -> String:
	return "shape%s_%s" % [get_shape_id(), param_name]

func _get(property: StringName) -> Variant:
	# Handle transforms directly from node_3d
	if node_3d:
		match property:
			"position":
				return node_3d.position
			"rotation":
				return node_3d.rotation
			"scale":
				return node_3d.scale
	
	if property in property_values:
		return property_values[property]
	return null

func _set(property: StringName, value: Variant) -> bool:
	# Handle transforms directly to node_3d
	if node_3d:
		match property:
			"position":
				node_3d.position = value
				return true
			"rotation":
				node_3d.rotation = value
				return true
			"scale":
				node_3d.scale = value
				return true
	
	if property in property_values:
		var param = _find_parameter(property)
		if param != null:
			property_values[property] = _validate_value(value, param)
			return true
	return false

func _find_parameter(property_name: String) -> Dictionary:
	var all_params = BASE_PARAMETERS + get_shape_parameters()
	for param in all_params:
		if param.name == property_name:
			return param
	return {}

func _validate_value(value: Variant, param: Dictionary) -> Variant:
	var validated_value = value
	
	if "min" in param:
		if param.type == TYPE_VECTOR3:
			validated_value = Vector3(
				max(value.x, param.get("min", -INF)),
				max(value.y, param.get("min", -INF)),
				max(value.z, param.get("min", -INF))
			)
		elif param.type == TYPE_VECTOR2:
			validated_value = Vector2(
				max(value.x, param.get("min", -INF)),
				max(value.y, param.get("min", -INF))
			)
		else:
			validated_value = max(value, param.get("min", -INF))
			
	if "max" in param:
		if param.type == TYPE_VECTOR3:
			validated_value = Vector3(
				min(validated_value.x, param.get("max", INF)),
				min(validated_value.y, param.get("max", INF)),
				min(validated_value.z, param.get("max", INF))
			)
		elif param.type == TYPE_VECTOR2:
			validated_value = Vector2(
				min(validated_value.x, param.get("max", INF)),
				min(validated_value.y, param.get("max", INF))
			)
		else:
			validated_value = min(validated_value, param.get("max", INF))
			
	return validated_value

# Virtual method for shapes to override with their specific parameters
func get_shape_parameters() -> Array:
	return []

# Virtual method for shapes to implement their SDF function with unique instance ID
func get_sdf_function() -> String:
	push_error("Base class method called")
	return ""

# Virtual method for shapes to implement their SDF call with unique instance ID
func get_sdf_call() -> String:
	push_error("Base class method called")
	return ""

# Helper method to get all parameters as a dictionary
func get_all_parameters() -> Dictionary:
	var params = {}
	if node_3d:
		# Add transform parameters directly from node_3d
		params["position"] = node_3d.position
		params["rotation"] = node_3d.rotation
		params["scale"] = node_3d.scale
	# Add other parameters
	for key in property_values:
		params[key] = property_values[key]
	return params
