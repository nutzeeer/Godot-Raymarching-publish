# refractive_modifier.gd
class_name RefractiveModifier217
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "refraction_index",
		"type": TYPE_FLOAT,
		"default": 1.5,
		"min": 1.0,
		"description": "Index of refraction"
	},
	{
		"name": "albedo_color",
		"type": TYPE_COLOR,
		"default": Color(0.1, 0.3, 0.8, 1.0),
		"description": "Color applied to refracted light"
	},
	{
		"name": "albedo_strength",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of the albedo color effect"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	// Check for intersection with refractive medium
	float r = map_refractive(pos);
	if (r < current_accuracy) {
		
		current_rd = calculate_refraction(current_rd, getNormal(pos), {refraction_index}); //refraction upon entering the medium

		//This is an internal loop to step through the refractive medium.
		// Steps through refractive medium and returns exit point

	vec3 entry_pos = pos;
	float t = 0.0;

	
	// March through the medium until we exit
	for(; i < MAX_STEPS; i++) { //Using i of the main loop to not exceed max steps.
		float ref_d = map_refractive(entry_pos);
		
		// Check if we've exited the medium
		if (ref_d >= current_accuracy) {
			ALBEDO += {albedo_color} * {albedo_strength};
			ray_origin = entry_pos;
			t = 0.001; // Reset distance traveled since we have a new ray origin. Add current accuracy to start outside of object.
			break;
		}
		// Inside medium - continue stepping
		t += max(abs(ref_d), current_accuracy * 2.0);
		entry_pos = entry_pos + current_rd + t;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		// Safety check
		if (t > MAX_DISTANCE) break;
	}
	// Return final position if we didn't find exit
	//ray_origin = entry_pos;

		//pos = ray_origin;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		t = 0.001; // Reset distance traveled since we have a new ray origin. Add current accuracy to start outside of object.
		
		current_rd = calculate_refraction(current_rd, getNormal(ray_origin+current_rd*current_accuracy), 1.0/{refraction_index});
		continue;
	}
	"""

func get_utility_functions() -> String:
	return """
// Refraction calculation using Snell's law
vec3 calculate_refraction(vec3 incident, vec3 normal, float ior) {
	float cos_i = clamp(dot(normal, incident), -1.0, 1.0);
	float eta = (cos_i < 0.0) ? 1.0/ior : ior;
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
