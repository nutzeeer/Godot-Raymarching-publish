# return_line_modifier_wave.gd
class_name scaresinwave
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
	// Calculate wave effect based on position along wave axis
	float wave = dot(p, normalize({wave_axis}));
	float wave_effect = sin(wave * {wave_frequency}) * {wave_amplitude};

	// Apply wave effect to the SDF result
	d = d * (1.0 + wave_effect);
	"""
