# general_modifier_base.gd
class_name GeneralModifierBase
extends Resource

const BASE_PARAMETERS = []

var property_values: Dictionary = {}
var node_3d: Node3D

func _init() -> void:
	_setup_parameters()
	resource_name = "GeneralModifierBase"

func _setup_parameters() -> void:
	var all_params = BASE_PARAMETERS + get_modifier_parameters()
	for param in all_params:
		if "default" in param:
			property_values[param.name] = param.default
		else:
			match param.type:
				TYPE_FLOAT: property_values[param.name] = 0.0
				TYPE_INT: property_values[param.name] = 0
				TYPE_VECTOR2: property_values[param.name] = Vector2.ZERO
				TYPE_VECTOR3: property_values[param.name] = Vector3.ZERO
				TYPE_BASIS: property_values[param.name] = Basis.IDENTITY
				TYPE_TRANSFORM3D: property_values[param.name] = Transform3D.IDENTITY
				_: property_values[param.name] = null

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

func _validate_value(value: Variant, param: Dictionary) -> Variant:
	if value == null:
		return param.get("default", null)
	
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

func process_template(template: String) -> String:
	var processed = template
	for param_name in property_values:
		var value = property_values[param_name]
		var placeholder = "{" + param_name + "}"
		
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

# Modifier type checking
func has_d_modifier() -> bool:
	return get_d_modifier_template() != ""

func has_p_modifier() -> bool:
	return get_p_modifier_template() != ""

func has_color_modifier() -> bool:
	return get_color_modifier_template() != ""
	
func get_pre_map_functions() -> String:
	return ""  # Base class returns empty string


func has_forloop_modifier() -> bool:
	return get_forloop_modifier_template() != ""

# Virtual methods for modifiers to implement
func get_modifier_parameters() -> Array:
	return []

func get_d_modifier_template() -> String:
	return ""

func get_p_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""

func get_forloop_modifier_template() -> String:
	return ""  # Base class returns empty string
	
	# general_modifier_base.gd
func get_utility_functions() -> String:
	return ""  # Base returns empty string

func get_custom_map_name() -> String:
	return ""  # Base returns empty string - no custom map needed

func get_custom_map_template() -> String:
	return ""  # Base returns empty string

func get_all_parameters() -> Dictionary:
	var params = {}
	for key in property_values:
		params[key] = property_values[key]
	return params
