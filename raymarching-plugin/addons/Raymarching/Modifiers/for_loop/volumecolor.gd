# volume_color_modifier.gd
class_name VolumeColorModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "volume_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.3, 0.6, 0.9),
		"description": "Color of the volume"
	},
	{
		"name": "color_strength",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 10.0,
		"description": "Strength of the color effect"
	},
	{
		"name": "step_multiplier",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.5,
		"max": 10.0,
		"description": "Controls detail level of volume sampling"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	// Check for intersection with volume
	float vol_d = map_volume(pos);
	
	// Double the accuracy for volumes to detect them before surfaces
	if (vol_d < current_accuracy * 2.0) {
		// Store original position to continue after volume
		vec3 original_pos = pos;
		
		// Track distance through volume
		float total_distance = 0.0;
		vec3 current_pos = pos;
		float step_size = 0.0;
		
		// Step through volume
		for(int vol_i = 0; vol_i < 32; vol_i++) {
			// Check if we're still in volume
			float d = map_volume(current_pos);
			
			// Exit if we're out of the volume
			if (d >= current_accuracy * 2.0) {
				break;
			}
			
			// Add color based on current step (stronger near center of volume)
			vec3 addedColor = {volume_color} * {color_strength} * (1.0 - d / (current_accuracy * 2.0)) * 0.05;
			ALBEDO = clamp(ALBEDO + addedColor, 0.0, 1.0);
			
			// Take a step
			step_size = max(abs(d), current_accuracy * {step_multiplier});
			total_distance += step_size;
			current_pos += current_rd * step_size;
			
			// Safety check
			if (total_distance > MAX_DISTANCE) break;
		}
		
		// Debug: Force a visible color to verify code is executing
		//ALBEDO = mix(ALBEDO, vec3(1.0, 0.0, 0.0), 0.3);  // Remove this after debugging
		
		// Continue ray from exit point
		ray_origin = current_pos;
		t = 0.001;
		continue;
	}
	"""

func get_custom_map_name() -> String:
	return "map_volume"
