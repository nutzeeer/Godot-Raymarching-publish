# return_line_modifier_base.gd
class_name ReturnLineModifierBase
extends Resource

const BASE_PARAMETERS = [
	# Common parameters for all modifiers if needed
]

var property_values: Dictionary = {}
var node_3d: Node3D  # Reference to the shape node if needed

func _init() -> void:
	_setup_parameters()
	resource_name = "ReturnLineModifierBase"

func _setup_parameters() -> void:
	var all_params = BASE_PARAMETERS + get_modifier_parameters()
	for param in all_params:
		# Initialize with default value from parameter definition
		if "default" in param:
			property_values[param.name] = param.default
		else:
			# Provide type-appropriate defaults if no default specified
			match param.type:
				TYPE_FLOAT:
					property_values[param.name] = 0.0
				TYPE_INT:
					property_values[param.name] = 0
				TYPE_VECTOR2:
					property_values[param.name] = Vector2.ZERO
				TYPE_VECTOR3:
					property_values[param.name] = Vector3.ZERO
				TYPE_BASIS:  # For 3x3 matrices (mat3)
					property_values[param.name] = Basis.IDENTITY
				TYPE_TRANSFORM3D:  # For 4x4 matrices (mat4)
					property_values[param.name] = Transform3D.IDENTITY
				_:
					property_values[param.name] = null

func set_node_3d(node: Node3D) -> void:
	node_3d = node

func get_modifier_id() -> String:
	return str(node_3d.get_instance_id()) if node_3d else "0"

func get_parameter_name(param_name: String) -> String:
	return "modifier%s_%s" % [get_modifier_id(), param_name]

func _get(property: StringName) -> Variant:
	if property in property_values:
		return property_values[property]
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property in property_values:
		var param = _find_parameter(property)
		if param != null:
			property_values[property] = _validate_value(value, param)
			return true
	return false

func _find_parameter(property_name: String) -> Dictionary:
	var all_params = BASE_PARAMETERS + get_modifier_parameters()
	for param in all_params:
		if param.name == property_name:
			return param
	return {}
# In return_line_modifier_base.gd

func _validate_value(value: Variant, param: Dictionary) -> Variant:
	# If value is null, return the default value or a type-appropriate default
	if value == null:
		if "default" in param:
			return param.default
		
		match param.type:
			TYPE_FLOAT:
				return 0.0
			TYPE_INT:
				return 0
			TYPE_VECTOR2:
				return Vector2.ZERO
			TYPE_VECTOR3:
				return Vector3.ZERO
			_:
				return null
	
	var validated_value = value
	
	if "min" in param:
		match param.type:
			TYPE_VECTOR3:
				validated_value = Vector3(
					max(value.x, param.min),
					max(value.y, param.min),
					max(value.z, param.min)
				)
			TYPE_VECTOR2:
				validated_value = Vector2(
					max(value.x, param.min),
					max(value.y, param.min)
				)
			_:
				validated_value = max(value, param.min)
	
	if "max" in param:
		match param.type:
			TYPE_VECTOR3:
				validated_value = Vector3(
					min(validated_value.x, param.max),
					min(validated_value.y, param.max),
					min(validated_value.z, param.max)
				)
			TYPE_VECTOR2:
				validated_value = Vector2(
					min(validated_value.x, param.max),
					min(validated_value.y, param.max)
				)
			_:
				validated_value = min(validated_value, param.max)
	
	return validated_value
	
# Virtual methods for modifiers to implement
func get_modifier_parameters() -> Array:
	return []

func get_modifier_template() -> String:
	push_error("Base class method called")
	return ""
	
	# Add to return_line_modifier_base.gd
func process_template(template: String) -> String:
	var processed = template
	for param_name in property_values:
		var value = property_values[param_name]
		var placeholder = "{" + param_name + "}"
		
		# Convert value to GLSL compatible string
		var glsl_value = ""
		match typeof(value):
			TYPE_VECTOR3:
				glsl_value = "vec3(%f, %f, %f)" % [value.x, value.y, value.z]
			TYPE_VECTOR2:
				glsl_value = "vec2(%f, %f)" % [value.x, value.y]
			_:
				glsl_value = str(value)
				
		processed = processed.replace(placeholder, glsl_value)
	return processed

func get_all_parameters() -> Dictionary:
	var params = {}
	for key in property_values:
		params[key] = property_values[key]
	return params
