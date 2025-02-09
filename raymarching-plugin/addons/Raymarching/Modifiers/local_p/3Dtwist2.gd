class_name ViewCompensatedTwistModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "twist_amount",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": -10.0,
		"max": 10.0,
	},
	{
		"name": "twist_axis",
		"type": TYPE_VECTOR3,
		"default": Vector3(0, 1, 0),
	},
	{
		"name": "twist_center",
		"type": TYPE_VECTOR3,
		"default": Vector3.ZERO,
	},
	{
		"name": "falloff_radius",
		"type": TYPE_FLOAT,
		"default": 5.0,
		"min": 0.1,
		"max": 20.0,
	}
]

#func get_custom_map_name() -> String:
	#return "map_view_compensated"
#
#func get_custom_map_template() -> String:
	#return """
	#float map_view_compensated(vec3 p, vec3 ray_dir) {
		#float d = MAX_DISTANCE;
		#${SHAPES_CODE}
		#return d;
	#}
	#"""

func get_p_modifier_template() -> String:
	return """
	vec3 axis = normalize({twist_axis});
	vec3 to_point = normalize(ray_dir);
	float view_factor = abs(dot(to_point, axis));
	
	vec3 relative_pos = p - {twist_center};
	float height = dot(relative_pos, axis);
	vec3 projected = height * axis;
	vec3 orthogonal = relative_pos - projected;
	
	float dist_from_axis = length(orthogonal);
	float falloff = 1.0 - smoothstep(0.0, {falloff_radius}, dist_from_axis);
	
	float adjusted_twist = {twist_amount} * (1.0 + (1.0 - view_factor) * 2.0);
	float angle = height * adjusted_twist * falloff;
	
	float c = cos(angle);
	float s = sin(angle);
	vec3 rotated = orthogonal * c + cross(axis, orthogonal) * s;
	
	vec3 result = rotated + projected + {twist_center};
	"""
