# refractive_modifier.gd
class_name RefractiveModifieryyy
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
		"name": "max_bounces",
		"type": TYPE_INT,
		"default": 8,
		"min": 1,
		"max": 32,
		"description": "Maximum internal bounces"
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
		
		// Handle multi-bounce refraction
		RefractionResult result = handle_refraction_bounce(
			current_rd, 
			normal,
			pos,
			{refraction_index},
			{max_bounces}
		);
		
		if(result.should_continue) {
			current_rd = result.new_direction;
			t += current_accuracy * 2.0;  // Step a bit more to get inside
			current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
			continue;
		}
	}
	"""

func get_utility_functions() -> String:
	return """
	struct RefractionResult {
		vec3 new_direction;
		bool should_continue;
		vec3 color_contribution;
	};
	
	RefractionResult handle_refraction_bounce(
		vec3 incident, 
		vec3 normal, 
		vec3 pos,
		float ior,
		int max_bounces
	) {
		RefractionResult result;
		result.should_continue = false;
		result.color_contribution = vec3(0.0);
		
		// Calculate fresnel term
		float fresnel = pow(1.0 + dot(incident, normal), 5.0);
		
		// Calculate primary refraction
		float cos_i = clamp(dot(normal, incident), -1.0, 1.0);
		float eta = (cos_i < 0.0) ? ior : 1.0/ior;
		cos_i = abs(cos_i);
		
		float k = 1.0 - eta * eta * (1.0 - cos_i * cos_i);
		
		if (k < 0.0) {
			// Total internal reflection
			result.new_direction = reflect(incident, normal);
			result.should_continue = true;
			return result;
		}
		
		// Calculate refracted direction
		vec3 refracted = eta * incident + (eta * cos_i - sqrt(k)) * normal;
		
		// Split ray based on fresnel
		if (fresnel > 0.0) {
			vec3 reflected = reflect(incident, normal);
			result.new_direction = mix(refracted, reflected, fresnel);
		} else {
			result.new_direction = refracted;
		}
		
		result.should_continue = true;
		return result;
	}
	
	// Original refraction calculation kept for reference
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

func get_custom_map_template() -> String:
	return """
	float map_refractive(vec3 p) {
		float final_distance = MAX_DISTANCE;
		${SHAPES_CODE}
		return final_distance;
	}
	"""
