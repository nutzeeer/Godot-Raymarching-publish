# twist_modifier.gd
class_name TwistModifier2
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
	},
	{
		"name": "falloff_distance",
		"type": TYPE_FLOAT,
		"default": 5.0,
		"min": 0.1,
		"max": 20.0,
		"description": "Distance over which twist effect fades out"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_p_modifier_template() -> String:
	return """
	// Move to twist center
	vec3 relative_pos = p - {twist_center};
	
	// Project onto twist axis
	vec3 axis = normalize({twist_axis});
	float height = dot(relative_pos, axis);
	vec3 projected = height * axis;
	vec3 orthogonal = relative_pos - projected;
	
	// Calculate distance from axis for falloff
	float dist_from_axis = length(orthogonal);
	float falloff = 1.0 - smoothstep(0.0, {falloff_distance}, dist_from_axis);
	
	// Calculate twist angle with falloff
	float angle = height * {twist_amount} * falloff;
	
	// Create stable rotation
	float c = cos(angle);
	float s = sin(angle);
	
	// Build rotation only in plane perpendicular to axis
	vec3 rotated = orthogonal * c + cross(axis, orthogonal) * s;
	
	// Reconstruct position with rotated orthogonal component
	vec3 result = rotated + projected + {twist_center};
	"""

func get_d_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
