# cheap_sinwave.gd
class_name negative
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [

]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_d_modifier_template() -> String:
	return """

	d = -d;
	"""

# These are optional since has_x_modifier() checks if get_x_modifier_template() returns non-empty
func get_p_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
