# twist_modifier.gd
class_name TwistModifier3D
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

func get_p_modifier_template() -> String:
	return """
	// Move to twist center
	vec3 relative_pos = p - {twist_center};
	
	// Calculate both height and radial distance from twist axis
	vec3 projected = normalize({twist_axis}) * dot(relative_pos, normalize({twist_axis}));
	vec3 perpendicular = relative_pos - projected;
	float radius = length(perpendicular);
	float height = dot(relative_pos, normalize({twist_axis}));
	
	// Calculate twist angle based on cylindrical coordinates
	float dist = sqrt(radius * radius + height * height);  // Total distance from center
	float angle = dist * {twist_amount};
	
	// Create rotation matrix around twist axis
	vec3 axis = normalize({twist_axis});
	float c = cos(angle);
	float s = sin(angle);
	float t = 1.0 - c;
	mat3 rot = mat3(
		vec3(t * axis.x * axis.x + c,        t * axis.x * axis.y - s * axis.z, t * axis.x * axis.z + s * axis.y),
		vec3(t * axis.x * axis.y + s * axis.z, t * axis.y * axis.y + c,        t * axis.y * axis.z - s * axis.x),
		vec3(t * axis.x * axis.z - s * axis.y, t * axis.y * axis.z + s * axis.x, t * axis.z * axis.z + c)
	);
	
	// Apply twist transformation and return
	vec3 result = rot * relative_pos + {twist_center};
	"""

# These return empty since we only modify the position
func get_d_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
