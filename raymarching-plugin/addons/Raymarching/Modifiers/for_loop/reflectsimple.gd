# reflection_modifier.gd
class_name ReflectionModifiersimple
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "reflection_strength",
		"type": TYPE_FLOAT,
		"default": 0.8,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of the reflection (0 = no reflection, 1 = perfect mirror)"
	},
	{
		"name": "max_bounces",
		"type": TYPE_INT,
		"default": 1,
		"min": 1,
		"max": 3,
		"description": "Maximum number of reflection bounces"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	// Check for reflection
	float f = map_simpleflect(pos);
	if (f < current_accuracy) {
		// Get surface normal at hit point
		vec3 normal = getNormal(pos);
		
		// Calculate reflection direction
		vec3 reflection_dir = reflect(current_rd, normal);
		
		// Apply reflection with strength factor
		current_rd = normalize(mix(current_rd, reflection_dir, {reflection_strength}));
		
		// Move slightly away from surface to avoid self-intersection
		t += current_accuracy * 2.0;
		
		// Check if we've exceeded max bounces
		if (i >= {max_bounces} * (MAX_STEPS / 4)) {
			break;
		}
		
		continue;
	}
	"""

func get_custom_map_name() -> String:
	return "map_simpleflect"

# These return empty since we only modify the ray direction in the for loop
func get_d_modifier_template() -> String:
	return ""

func get_p_modifier_template() -> String:
	return ""

func get_color_modifier_template() -> String:
	return ""
