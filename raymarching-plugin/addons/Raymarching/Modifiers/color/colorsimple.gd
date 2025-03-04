# color_modifier.gd
class_name ColorModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "color",
		"type": TYPE_VECTOR3,
		"default": Vector3(1.0, 1.0, 0.0),
		"description": "Surface color (RGB)"
	},
	{
		"name": "intensity",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 5.0,
		"description": "Color intensity multiplier"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

# Only implement color modification
func get_color_modifier_template() -> String:
	return """
	// Set surface color with intensity
	ALBEDO *= {color} * {intensity};
	"""

# These return empty since we only modify the color
func get_d_modifier_template() -> String:
	return ""

func get_p_modifier_template() -> String:
	return ""

func get_forloop_modifier_template() -> String:
	return ""
	
