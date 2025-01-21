# General_modifier_template.gd
class_name GeneralModifierTemplate
extends GeneralineModifierBase

const MODIFIER_PARAMETERS = [
	# Define modifier-specific parameters here
	{"name": "d_parameter_name", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0},
	{"name": "p_parameter_name", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0},
	{"name": "color_parameter_name", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0},

]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_d_modifier_template() -> String:
	return """
	// Template for modifier code affecting the sdf Result
	// Use {d_parameter_name} for parameter placeholders
	// 'result' variable contains the current SDF value. 
	// Good for effects.
	d = d * {parameter_name};
	"""
	
func get_p_modifier_template() -> String:
	return """
	// Template for modifier code affecting the sdf world space.
	// Use {p_parameter_name} for parameter placeholders
	// local_p is the variable reused for each shape.
	// 'local_p' variable contains the current SDF coordinates. 
	// Good for deformations.
	local_p = local_p * {p_parameter_name};
	"""

func get_color_modifier_template() -> String:
	return """
	// Template for modifier code affecting the sdf rendering/ surface/ result usage
	// Use {color_parameter_name} for parameter placeholders
	// 'color' variable contains the current SDF Surface
	// Good for a lot.
	color = color * {color_parameter_name};
	"""
