# twist_modifier.gd
class_name DTwistModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "twist_amount",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": -10.0,
		"max": 10.0,
		"description": "Amount of twist along the axis"
	},
	{
		"name": "twist_axis", 
		"type": TYPE_VECTOR3,
		"default": Vector3(0, 1, 0),
		"description": "Axis to twist around"
	},
	{
		"name": "twist_center",
		"type": TYPE_VECTOR3,
		"default": Vector3.ZERO,
		"description": "Center point of the twist"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_d_modifier_template() -> String:
	return """
	// Calculate twist influence based on distance from axis
	vec3 relative_pos = local_p - {twist_center};
	float height = dot(relative_pos, normalize({twist_axis}));
	float dist_from_axis = length(relative_pos - height * normalize({twist_axis}));
	
	// Smoothly vary the twist effect based on distance from axis
	float twist_influence = smoothstep(0.0, 1.0, dist_from_axis);
	
	// Apply twist modification to the distance field
	d += sin(height * {twist_amount}) * dist_from_axis * twist_influence;
	"""

# These return empty since we only modify the distance
func get_p_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
