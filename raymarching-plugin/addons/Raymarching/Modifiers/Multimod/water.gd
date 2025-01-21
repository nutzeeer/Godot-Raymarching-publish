# water_modifier.gd
class_name WaterModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "choppiness",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 2.0,
		"description": "Wave choppiness factor"
	},
	{
		"name": "foam_intensity",
		"type": TYPE_FLOAT,
		"default": 0.4,
		"min": 0.0,
		"max": 1.0,
		"description": "Foam accumulation intensity"
	},
	{
		"name": "water_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.1, 0.3, 0.4),
		"description": "Base water color (RGB)"
	},
	{
		"name": "wave_scale",
		"type": TYPE_FLOAT,
		"default": 3.0,
		"min": 0.1,
		"max": 10.0,
		"description": "Scale of wave patterns"
	},
	{
		"name": "depth_fade",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.1,
		"max": 10.0,
		"description": "Water depth fade factor"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_pre_map_functions() -> String:
	return """
// Layered noise for water waves
float water_noise(vec3 p, float scale) {
	float noise = 0.0;
	float amp = 1.0;
	vec3 pos = p * scale;
	
	// Layer 1: Main waves
	noise += sin(pos.x * 0.5 + TIME) * cos(pos.z * 0.3 + TIME * 0.7) * amp;
	amp *= 0.5;
	pos *= 2.0;
	
	// Layer 2: Secondary ripples
	noise += sin(pos.x * 0.7 - TIME * 1.3) * cos(pos.z * 0.8 + TIME) * amp;
	amp *= 0.5;
	pos *= 2.0;
	
	// Layer 3: Fine detail
	noise += sin(pos.x + TIME * 2.0) * cos(pos.z * 1.2 - TIME * 1.7) * amp;
	
	return noise;
}
"""

func get_utility_functions() -> String:
	return """
// Fresnel effect calculation
float fresnel(vec3 normal, vec3 view, float power) {
	return pow(1.0 - abs(dot(normal, view)), power);
}

// Edge foam calculation
float calculate_foam(vec3 p, float t, float intensity) {
	vec3 normal = getNormal(p);
	float height_foam = smoothstep(0.0, 1.0, abs(water_noise(p * 2.0, 1.0)));
	float edge_foam = 1.0 - smoothstep(0.0, 0.5, abs(t));
	return mix(edge_foam, height_foam, 0.5) * intensity;
}
"""
func get_d_modifier_template() -> String:
	return """
	// Apply wave displacement
	float wave_height = water_noise(local_p, {wave_scale}) * {choppiness};
	d += wave_height * 0.5;
	"""

func get_color_modifier_template() -> String:
	return """
	// Calculate water color and effects
	float foam = calculate_foam(hit_pos,t, {foam_intensity});
	float fresnel_factor = fresnel(hit_normal, -current_rd, 5.0);
	
	// Mix water color with foam and fresnel
	vec3 water_base = {water_color} * (1.0 -t * {depth_fade} * 0.1);
	vec3 foam_color = vec3(1.0);
	vec3 fresnel_color = vec3(0.8, 0.9, 1.0);
	
	// Combine all effects
	ALBEDO = mix(water_base, foam_color, foam);
	ALBEDO = mix(ALBEDO, fresnel_color, fresnel_factor * 0.6);
	
	// Add subtle caustics effect
	float caustics = abs(water_noise(hit_pos * 1.5 + TIME * 0.2, {wave_scale} * 0.5));
	ALBEDO += caustics * 0.1;
	"""

func get_forloop_modifier_template() -> String:
	return """
	// Adjust ray behavior in water volume
	if (d < current_accuracy) {
		current_rd *= 0.7 + water_noise(pos, {wave_scale}) * 0.1;
	}
	"""
