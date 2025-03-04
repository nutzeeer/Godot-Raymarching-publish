# volume_color_modifier.gd
class_name VolumeColorModifier12
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "volume_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.3, 0.6, 0.9),
		"description": "Base color of the volumetric effect"
	},
	{
		"name": "density",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 10.0,
		"description": "Density multiplier for color absorption"
	},
	{
		"name": "step_detail",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.5,
		"max": 10.0,
		"description": "Quality/performance trade-off for volume traversal"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	// Detect volume surface entry
	//float volume_dist = map_volume(pos);
	//if (volume_dist < current_accuracy) {
		// Traverse through volume to find exit point
		vec4 volume_pass = traverse_volume(pos, current_rd, current_accuracy, {step_detail});
		float depth = volume_pass.w;

		// Calculate volumetric effects
		vec3 absorption = (vec3(1.0) - {volume_color}.rgb) * {density};
		vec3 transmittance = exp(-absorption * depth);
		
		// Apply volume absorption and emission
		ALBEDO = ALBEDO * transmittance + {volume_color}.rgb * (1.0 - transmittance);
		//ALBEDO = clamp(ALBEDO, 0.0, 1.0);

		// Advance march to exit point
		ray_origin = volume_pass.xyz;
		current_accuracy = depth * SURFACE_DISTANCE * pixel_scale;
		t = 0.001;
		continue;
	//}
	"""

func get_utility_functions() -> String:
	return """
// Traverse through volume while maintaining original direction
vec4 traverse_volume(vec3 entry, vec3 dir, float precision, float step_scale) {
	float traveled = 0.0;
	vec3 current = entry;
	
	for(int i = 0; i < MAX_STEPS; i++) {
		float dist = map_volume(current);
		
		if (dist > precision) {
			return vec4(current, traveled);
		}
		
		// Adaptive stepping using modifier parameter
		float step_size = max(abs(dist), precision * step_scale);
		traveled += step_size;
		current = entry + dir * traveled;
		
		if (traveled > MAX_DISTANCE) break;
	}
	return vec4(current, traveled);
}
"""

func get_custom_map_name() -> String:
	return "map_volume"
