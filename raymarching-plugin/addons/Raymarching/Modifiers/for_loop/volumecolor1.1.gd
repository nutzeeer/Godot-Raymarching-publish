# volume_color_modifier.gd
class_name VolumeColorModifier11
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "volume_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.3, 0.6, 0.9),
		"description": "Color of the volume"
	},
	{
		"name": "color_strength",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 10.0,
		"description": "Strength of the color effect"
	},
	{
		"name": "step_multiplier",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.5,
		"max": 10.0,
		"description": "Controls detail level of volume sampling"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """

		vec3 addedColor = {volume_color} * {color_strength} * (t- prev_t); // add color based on step distance
		ALBEDO += addedColor;
		t += max(d,current_accuracy*{step_multiplier});
		//continue marching to perhaps hit surface in volume. volume should not be a march ending effect.
		continue;
	
	"""

func get_custom_map_name() -> String:
	return "map_volume"
