# volume_color_modifier.gd
class_name VolumeColorModifier11
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

	
	// Double the accuracy for volumes to detect them before surfaces
	if (d < current_accuracy * 2.0) {
		
	// Check for intersection with volume
	float vol_d = map_volume(pos);

	if (vol_d < current_accuracy*2.0){
		
		vec3 addedColor = {volume_color} * {color_strength} * (t- prev_t); // add color based on step distance
		ALBEDO += addedColor;
		t += max(abs(vol_d),current_accuracy*{step_multiplier});
		//continue marching to perhaps hit surface in volume. volume should not be a march ending effect.
		d+= vol_d; //adding the volumetric effect to not have d reach below the accuracy threshold with volume present. (if another object overlaps it )
		d= min(vol_d,d); //adjusting d to not hit the volumetric object. maybe a problem to not hit another object overlapping still.
		
	}
	}
	"""

func get_custom_map_name() -> String:
	return "map_volume"
