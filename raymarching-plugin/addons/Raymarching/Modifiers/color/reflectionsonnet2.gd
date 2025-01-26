# metallic_reflection_modifier.gd
class_name MetallicReflectionModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "metallic_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.1, 0.1, 0.),
		"description": "Base color of the metallic surface"
	},
	{
		"name": "roughness",
		"type": TYPE_FLOAT,
		"default": 0.1,
		"min": 0.001,
		"max": 1.0,
		"description": "Surface roughness (affects reflection blur)"
	},
	{
		"name": "reflection_strength",
		"type": TYPE_FLOAT,
		"default": 0.8,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of reflections"
	},
	{
		"name": "fresnel_power",
		"type": TYPE_FLOAT,
		"default": 5.0,
		"min": 1.0,
		"max": 10.0,
		"description": "Fresnel effect power"
	},
	{
		"name": "max_reflection_steps",
		"type": TYPE_INT,
		"default": 32,
		"min": 1,
		"max": 100,
		"description": "Maximum steps for reflection raymarching"
	},
	{
		"name": "reflection_distance",
		"type": TYPE_FLOAT,
		"default": 50.0,
		"min": 1.0,
		"max": 1000.0,
		"description": "Maximum reflection trace distance"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_color_modifier_template() -> String:
	return """
	// Calculate random value for roughness
	float rand_value = fract(sin(dot(SCREEN_UV, vec2(12.9898,78.233))) * 43758.5453);
	float rand_value2 = fract(sin(dot(SCREEN_UV.yx, vec2(12.9898,78.233))) * 43758.5453);
	
	// Calculate base metallic color
	vec3 base_color = {metallic_color};
	
	// Calculate view direction
	vec3 V = normalize(ray_origin - hit_pos);
	vec3 R = reflect(-V, hit_normal);
	
	// Create orthonormal basis for rough reflection
	vec3 uu = normalize(cross(hit_normal, vec3(0.0,1.0,1.0)));
	vec3 vv = cross(uu, hit_normal);
	
	// Add roughness perturbation
	float angle = rand_value * 2.0 * PI * {roughness};
	float z = rand_value2 * {roughness};
	vec3 perturb_dir = vec3(
		cos(angle) * sqrt(1.0 - z*z),
		sin(angle) * sqrt(1.0 - z*z),
		z
	);
	mat3 TBN = mat3(uu, vv, hit_normal);
	vec3 rough_R = normalize(mix(R, TBN * perturb_dir, {roughness}));
	
	// Calculate Fresnel
	float NdotV = max(dot(hit_normal, V), 0.0);
	float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - NdotV, {fresnel_power});
	
	// Trace reflection
	vec3 reflection_ro = hit_pos + hit_normal * 0.001;
	vec3 reflection = vec3(0.0);
	float rt = 0.01;
	bool reflection_hit = false;
	current_accuracy = 0.0;
	
	for(; i < {max_reflection_steps}; i++) {
		vec3 rp = reflection_ro + rough_R * rt;
		float rd = map(rp);
		
		if(rd < current_accuracy) {
			reflection_hit = true;
			vec3 rn = getNormal(rp);
			reflection = rn * 0.5 + 0.5;
			break;
		}
		
		rt += rd;
		current_accuracy = rt * SURFACE_DISTANCE * pixel_scale;  // Update at end like original

		if(rt > {reflection_distance}) break;
	}
	
	reflection = mix(vec3(0.1), reflection, reflection_hit ? 1.0 : 0.0);
	
	// Final color blend
	ALBEDO = mix(base_color, reflection, fresnel * {reflection_strength});
	"""

func get_d_modifier_template() -> String:
	return ""

func get_p_modifier_template() -> String:
	return ""
