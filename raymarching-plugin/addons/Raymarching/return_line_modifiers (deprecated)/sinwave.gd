# return_line_modifier_wave.gd
class_name sinwave
extends ReturnLineModifierBase

# Applies a wave effect to the SDF result based on the position
const MODIFIER_PARAMETERS = [
	{
		"name": "wave_amplitude",
		"type": TYPE_FLOAT,
		"default": 0.1,
		"min": 0.0,
		"max": 1.0,
		"description": "Amplitude of the wave effect"
	},
	{
		"name": "wave_frequency",
		"type": TYPE_FLOAT,
		"default": 5.0,
		"min": 0.1,
		"max": 20.0,
		"description": "Frequency of the wave effect"
	},
	{
		"name": "wave_axis",
		"type": TYPE_VECTOR3,
		"default": Vector3(0, 1, 0),
		"description": "Axis along which the wave effect is applied"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_modifier_template() -> String:
	return """
	// Project point onto wave axis
	vec3 wave_dir = normalize({wave_axis});
	float wave_dist = dot(local_p, wave_dir);
	
	// Calculate wave displacement vector instead of scalar
	vec3 wave_offset = wave_dir * sin(wave_dist * {wave_frequency}) * {wave_amplitude};
	
	// Calculate distance to the displaced surface
	vec3 displaced_p = local_p - wave_offset;
	float surface_influence = smoothstep(1.0, 0.0, abs(d) * 3.0);
	
	// Blend between original and displaced distance
	d = mix(d, length(displaced_p) - length(local_p) + d, surface_influence);
	"""
