# double_sided_march_modifier.gd
class_name DoubleSidedMarchModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "ior",
		"type": TYPE_FLOAT,
		"default": 1.5,
		"min": 1.0,
		"max": 3.0,
		"description": "Index of refraction"
	},
	{
		"name": "max_binary_steps",
		"type": TYPE_INT,
		"default": 8,
		"min": 4,
		"max": 16,
		"description": "Maximum binary search steps for surface refinement"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_utility_functions() -> String:
	return """
	vec3 find_surface_binary(vec3 a, vec3 b, float threshold, int max_steps) {
		for(int i = 0; i < max_steps; i++) {
			vec3 mid = mix(a, b, 0.5);
			float d = map_refractive(mid);
			if(abs(d) < threshold) return mid;
			if(d < 0.0) a = mid;
			else b = mid;
		}
		return mix(a, b, 0.5);
	}

	vec3 calculate_refraction_snell(vec3 incident, vec3 normal, float ior) {
		float cos_i = clamp(dot(normal, incident), -1.0, 1.0);
		float eta = (cos_i < 0.0) ? ior : 1.0/ior;
		cos_i = abs(cos_i);
		
		float k = 1.0 - eta * eta * (1.0 - cos_i * cos_i);
		if (k < 0.0) {
			return reflect(incident, normal);
		}
		return eta * incident + (eta * cos_i - sqrt(k)) * normal;
	}
	"""

func get_forloop_modifier_template() -> String:
	return """
	if ( d < current_accuracy) {  // Entering the surface
		vec3 prev_pos = pos - current_rd * d;
		vec3 surface_pos = find_surface_binary(prev_pos, pos, current_accuracy * 0.1, {max_binary_steps});
		vec3 normal = getNormal(surface_pos);
		
		current_rd = calculate_refraction_snell(current_rd, normal, {ior});
		t += current_accuracy * 4.0;  // Step inside
		continue;
	}
	else if (-d < current_accuracy) {  // Exiting the surface
		vec3 prev_pos = pos - current_rd * d;
		vec3 surface_pos = find_surface_binary(prev_pos, pos, current_accuracy * 0.1, {max_binary_steps});
		vec3 normal = -getNormal(surface_pos);  // Flip normal when exiting
		
		current_rd = calculate_refraction_snell(current_rd, normal, 1.0/{ior});
		t += current_accuracy * 4.0;  // Step outside
		continue;
	}
	
	t += d;
	"""

func get_custom_map_name() -> String:
	return "map_refractive"
