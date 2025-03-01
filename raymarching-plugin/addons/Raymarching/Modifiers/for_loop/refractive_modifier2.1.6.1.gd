# refractive_modifier.gd
class_name RefractiveModifier2161
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
		"type": TYPE_VECTOR3,
		"default": Vector3(0.1, 0.3, 0.8),
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
		// Step through the refractive medium and update march parameters
		vec4 refraction_result = step_through_refractive(pos, current_rd, current_accuracy, {refraction_index});
		
		// Calculate absorption coefficients from the color and strength
vec3 absorption = vec3(1.0) - {albedo_color}.rgb;  // Invert color to get absorption
absorption *= {albedo_strength};                   // Apply strength/density factor

// Calculate transmittance using Beer's law with t as the distance
vec3 transmittance = exp(-absorption * refraction_result.w);

// Apply transmittance to current color
ALBEDO *= transmittance;

// Calculate how much color to add based on the distance t
vec3 addedColor = {albedo_color}.rgb * {albedo_strength} * (1.0 - exp(-t * 0.5));

// Add to existing color
ALBEDO = clamp(ALBEDO + addedColor, 0.0, 1.0);
		
		ray_origin = refraction_result.xyz;
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
