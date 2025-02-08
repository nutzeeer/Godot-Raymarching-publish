class_name RefractiveModifier3
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "refraction_index",
		"type": TYPE_FLOAT,
		"default": 1.5,
		"min": 1.0,
		"max": 10.0,
		"description": "Index of refraction"
	},
	{
		"name": "red_ior_offset",
		"type": TYPE_FLOAT,
		"default": 0.0,
		"min": -0.1,
		"max": 0.1,
		"description": "Red channel IOR offset"
	},
	{
		"name": "blue_ior_offset",
		"type": TYPE_FLOAT,
		"default": 0.0,
		"min": -0.1,
		"max": 0.1,
		"description": "Blue channel IOR offset"
	},
	{
		"name": "fresnel_strength",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 5.0,
		"description": "Strength of fresnel effect"
	},
	{
		"name": "caustics_strength",
		"type": TYPE_FLOAT,
		"default": 0.0,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of caustic effects"
	},
	{
		"name": "chromatic_aberration",
		"type": TYPE_FLOAT,
		"default": 0.0,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of color separation"
	}
]
func get_forloop_modifier_template() -> String:
	return """
	float r = map_refractive(pos);
	if (r < current_accuracy) {
		// Calculate fresnel term
		float fresnel = calculate_fresnel(current_rd, getNormal(pos), {refraction_index}, {fresnel_strength});
		
		// Calculate chromatic aberration if enabled
		if ({chromatic_aberration} > 0.0) {
			vec3 color_shifts = calculate_chromatic_aberration(
				pos, 
				current_rd, 
				current_accuracy, 
				{refraction_index},
				{chromatic_aberration}
			);
			ALBEDO *= color_shifts;
		}
		
		// Calculate caustics
		if ({caustics_strength} > 0.0) {
			float caustic = calculate_caustics(pos, current_rd, {caustics_strength});
			ALBEDO *= (1.0 + caustic * {caustics_strength});
		}
		
		// Step through medium
		vec4 refraction_result = step_through_refractive(pos, current_rd, current_accuracy, {refraction_index});
		ray_origin = refraction_result.xyz;
		t = 0.0;
		current_rd = calculate_refraction(current_rd, getNormal(pos), {refraction_index});
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		
		// Apply fresnel reflection blend
		ALBEDO = mix(ALBEDO, reflect(current_rd, getNormal(pos)).xyz * 0.5 + 0.5, fresnel);
		
		continue;
	}
	"""

func get_utility_functions() -> String:
	return """
vec3 calculate_chromatic_aberration(vec3 pos, vec3 ray_dir, float accuracy, float base_ior, float strength) {
	// Use the offsets to modify the base IOR
	float red_ior = base_ior * (1.0 + {red_ior_offset} * strength);
	float blue_ior = base_ior * (1.0 + {blue_ior_offset} * strength);
	
	// March each color channel separately
	vec4 red_result = step_through_refractive(pos, ray_dir, accuracy, red_ior);     // Use calculated red_ior
	vec4 green_result = step_through_refractive(pos, ray_dir, accuracy, base_ior);
	vec4 blue_result = step_through_refractive(pos, ray_dir, accuracy, blue_ior);   // Use calculated blue_ior
	
	// Calculate color shifts based on distance differences
	float red_shift = 1.0 + (red_result.w - green_result.w) * strength;
	float blue_shift = 1.0 + (blue_result.w - green_result.w) * strength;
	
	return vec3(red_shift, 1.0, blue_shift);
}

float calculate_fresnel(vec3 incident, vec3 normal, float ior, float strength) {
	float cos_i = abs(dot(incident, normal));
	float sin_t = ior * sqrt(1.0 - cos_i * cos_i);
	float cos_t = sqrt(1.0 - sin_t * sin_t);
	
	float rs = (ior * cos_i - cos_t) / (ior * cos_i + cos_t);
	float rp = (cos_i - ior * cos_t) / (cos_i + ior * cos_t);
	
	float fresnel = 0.5 * (rs * rs + rp * rp) * strength;
	return clamp(fresnel, 0.0, 1.0);
}

float calculate_caustics(vec3 pos, vec3 ray_dir, float strength) {
	// Simple caustics approximation using surface normal variation
	vec3 normal = getNormal(pos);
	vec3 offset_normal = getNormal(pos + ray_dir * 0.01);
	
	// Calculate caustic intensity based on normal convergence
	float normal_difference = 1.0 - dot(normal, offset_normal);
	float caustic_intensity = pow(normal_difference * 10.0, 2.0);
	
	// Add some variation based on position
	float pattern = sin(pos.x * 10.0) * sin(pos.y * 10.0) * sin(pos.z * 10.0);
	
	return caustic_intensity * (0.5 + 0.5 * pattern);
}

// Previous utility functions remain the same...

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

// Steps through refractive medium and returns exit point
vec4 step_through_refractive(vec3 entry_pos, vec3 ray_dir, float accuracy, float ior) {
	vec3 pos = entry_pos;
	float t = 0.0;
	float step_accuracy = accuracy;
	
	// March through the medium until we exit
	for(int i = 0; i < MAX_STEPS; i++) {
		float d = map_refractive(pos);
		
		// Check if we've exited the medium
		if (d >= accuracy) {
			return vec4(pos, t);
		}
		
		// Inside medium - continue stepping
		t += max(abs(d), accuracy * 2.0);
		pos = entry_pos + ray_dir * t;
		step_accuracy = t * SURFACE_DISTANCE * 0.001;
		
		// Safety check
		if (t > MAX_DISTANCE) break;
	}
	
	// Return final position if we didn't find exit
	return vec4(pos, t);
}
"""

func get_custom_map_name() -> String:
	return "map_refractive"
