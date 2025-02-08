# refractive_modifier.gd
class_name RefractiveModifier21
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "refraction_index",
		"type": TYPE_FLOAT,
		"default": 1.5,
		"min": 1.0,
		"description": "Index of refraction"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	// Check for intersection with refractive medium
	float r = map_refractive(pos);
	if (r < current_accuracy) {
		vec3 normal = getNormal(pos);
		current_rd = calculate_refraction(current_rd, normal, {refraction_index});
		t += current_accuracy * 2.0;  // Step a bit more to get inside
		if (r < 0.0){
			t -= d;
		}
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		ray_origin = pos;
		continue;
	}
	"""

# refractive_modifier.gd
func get_utility_functions() -> String:
	return """
// Refraction calculation using Snell's law
vec3 calculate_refraction(vec3 incident, vec3 normal, float ior) {
	float cos_i = clamp(dot(normal, incident), -1.0, 1.0);
	float eta = (cos_i < 0.0) ? ior : 1.0/ior;
	cos_i = abs(cos_i);
	
	float k = 1.0 - eta * eta * (1.0 - cos_i * cos_i);
	if (k < 0.0) {
		// Total internal reflection
		return reflect(incident, normal);
	}
	
	return eta * incident + (eta * cos_i - sqrt(k)) * normal;
}
"""

func get_custom_map_name() -> String:
	return "map_refractive"
