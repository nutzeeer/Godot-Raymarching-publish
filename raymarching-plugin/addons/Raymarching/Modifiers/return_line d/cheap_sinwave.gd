# cheap_sinwave.gd
class_name CheapSinwave
extends GeneralModifierBase

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

func get_d_modifier_template() -> String:
	return """
	// Calculate wave effect based on position along wave axis
	float wave = dot(local_p, normalize({wave_axis}));
	float wave_effect = sin(wave * {wave_frequency}) * {wave_amplitude};
	// Apply wave effect only near the surface
	float surface_influence = smoothstep(1.0, 0.0, abs(d) * 5.0); // Smoother transition
	// Mix between original distance and wave-modified distance based on surface proximity
	d = mix(d, d + wave_effect, surface_influence);
	"""

# These are optional since has_x_modifier() checks if get_x_modifier_template() returns non-empty
func get_p_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
