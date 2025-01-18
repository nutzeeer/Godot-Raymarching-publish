# return_line_modifier_template.gd
class_name ReturnLineModifierTemplate
extends ReturnLineModifierBase

const MODIFIER_PARAMETERS = [
	# Define modifier-specific parameters here
	{"name": "parameter_name", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_modifier_template() -> String:
	return """
	// Template for modifier code
	// Use {parameter_name} for parameter placeholders
	// 'result' variable contains the current SDF value
	// Modify result as needed
	d = d * {parameter_name};
	"""
