# modifier_template.gd
class_name ModifierTemplate
extends GeneralModifierBase

#THIS IS NOT NECESSARILY CORRECT. needs its content checkted. But the gist is alright.

# Define modifier parameters that will be exposed in the UI
# Each parameter should include:
# - name: Parameter identifier
# - type: GDScript type (TYPE_FLOAT, TYPE_VECTOR3, etc.)
# - default: Default value
# - min/max: Optional range constraints
# - description: Parameter description
const MODIFIER_PARAMETERS = [
	{
		"name": "parameter_name",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,  # Optional
		"max": 10.0, # Optional
		"description": "Description of the parameter"
	}
	# Add additional parameters as needed
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

# Position Modification Template
# - Modifies the position (p) before SDF calculation
# - Redefines p as modified p to avoid overwriting the variable used by all shapes.
# - Must return a vec3 position value
# - Use {parameter_name} to reference parameters
func get_p_modifier_template() -> String:
	return """
	// Calculate modified position
	vec3 modified_p = p with /* position modification logic */; 
	vec3 result = modified_p;  # Final modified position must be stored in 'result'
	"""

# Distance Modification Template
# - Modifies the calculated distance field value (d)
# - Operates on the 'd' variable directly
# - Has access to local_p (position) and original d value
func get_d_modifier_template() -> String:
	return """
	// Modify the distance field value
	float modified_d = /* distance modification logic */;
	d = modified_d;  # Modified distance must be stored in 'd'
	"""

# For Loop Modification Template
# - Modifies ray behavior during marching
# - Has access to:
#   - pos: current position
#   - current_rd: current ray direction
#   - ro: ray_origin
#   - t: current distance traveled
#   - current_accuracy: current minimum step size
func get_forloop_modifier_template() -> String:
	return """
	// Modify ray marching behavior
	if (/* condition */) {
		/* modify current_rd, t, or other march parameters */
		continue;  // Optional: skip to next iteration. can also use break and discard.
	}
	"""

# Custom Map Function
# - Creates a specialized SDF map for specific effects.
# Returns the name of the custom map function
func get_custom_map_name() -> String:
	return "map_custom"

# Template for the custom map function
# Usage in conjunction with for loop effects. To select with shapes effect is applied to.
# - For loop effects need a custom map name and template.
# - Any custom map needs a for loop modifier using this map.
func get_custom_map_template() -> String:
	return """
	float map_custom(vec3 p) {
		float final_distance = MAX_DISTANCE;
		${SHAPES_CODE}  # Will be replaced with relevant shape calculations
		return final_distance;
	}
	"""

# Utility Functions
# - Additional GLSL functions needed by the modifier
# - Anything that needs to be called multiple times
func get_utility_functions() -> String:
	return """
	// Add any helper functions needed by the modifier
	float helper_function(float input) {
		return /* calculation */;
	}
	"""

# Color/Surface Modification Template
# - Modifies final surface appearance
# - Has access to ALBEDO and other surface parameters
func get_color_modifier_template() -> String:
	return """
	// Modify surface appearance
	ALBEDO = /* modified color */; //can use += *= /= -=. whatever you might want.
	"""
