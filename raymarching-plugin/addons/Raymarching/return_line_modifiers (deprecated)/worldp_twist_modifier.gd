# twist_modifier.gd
class_name TwistModifier
extends ReturnLineModifierBase

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

# In twist_modifier.gd

func get_modifier_template() -> String:
	return """
	// Move to twist center
	vec3 twisted_p = p - {twist_center};
	
	// Calculate twist angle based on height along twist axis
	float height = dot(twisted_p, {twist_axis});
	float angle = height * {twist_amount};
	
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
	
	// Apply twist transformation
	twisted_p = rot * twisted_p;
	twisted_p += {twist_center};
	
	// Scale result based on distance change
	d = d * length(twisted_p - {twist_center}) / length(p - {twist_center});
	"""
