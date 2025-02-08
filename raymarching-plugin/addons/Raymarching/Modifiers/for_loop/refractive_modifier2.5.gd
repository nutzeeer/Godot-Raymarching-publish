# refractive_modifier.gd
class_name RefractiveModifier25
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

func get_utility_functions() -> String:
	return """
// Single march step calculation
vec3 march_step(vec3 origin, vec3 direction, float start_t, out float new_t) {
	vec3 pos = origin + direction * start_t;
	float d = map(pos);
	new_t = start_t + d;
	return origin + direction * new_t;
}

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

func get_forloop_modifier_template() -> String:
	return """
	// Check for intersection with refractive medium
	float r = map_refractive(pos);
	if (r < current_accuracy) {
		vec3 normal = getNormal(pos);
		vec3 new_rd = calculate_refraction(current_rd, normal, {refraction_index});
		
		// Step slightly inside and do one march step with new direction
		vec3 new_origin = pos + normal * current_accuracy * 2.0;
		float new_t;
		vec3 new_pos = march_step(new_origin, new_rd, current_accuracy, new_t);
		
		// Check if we're exiting the medium
		float r_new = map_refractive(new_pos);
		if (r_new < 0.0) {
			// We're inside, adjust for exit
			normal = -getNormal(new_pos);
			new_rd = calculate_refraction(new_rd, normal, 1.0/{refraction_index});
			new_origin = new_pos + normal * current_accuracy * 2.0;
			new_pos = march_step(new_origin, new_rd, current_accuracy, new_t);
		}
		
		// Update state for next iteration
		ray_origin = new_origin;
		current_rd = new_rd;
		pos = new_pos;
		t = new_t;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		
		continue;
	}
	"""

func get_custom_map_name() -> String:
	return "map_refractive"

func get_custom_map_template() -> String:
	return """
	float map_refractive(vec3 p) {
		float final_distance = MAX_DISTANCE;
		${SHAPES_CODE}  // Will be replaced with shape calculations
		return final_distance;
	}
	"""
