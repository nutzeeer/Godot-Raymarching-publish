# reflection_modifier.gd
class_name ReflectionModifier2
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "base_color",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.1, 0.1, 0.1),
		"description": "Base color of the reflective surface"
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
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_forloop_modifier_template() -> String:
	return """
	float r = map_reflective(pos);
	if (r < current_accuracy) {
		vec3 normal = getNormal(pos);
		vec3 V = normalize(ray_origin - pos);
		
		// Calculate Fresnel effect
		float NdotV = max(dot(normal, V), 0.0);
		float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - NdotV, {fresnel_power});
		
		// Calculate roughness perturbation
		float rand_value = fract(sin(dot(pos.xy, vec2(12.9898,78.233))) * 43758.5453);
		float rand_value2 = fract(sin(dot(pos.yz, vec2(12.9898,78.233))) * 43758.5453);
		
		// Create orthonormal basis for rough reflection
		vec3 uu = normalize(cross(normal, vec3(0.0,1.0,1.0)));
		vec3 vv = cross(uu, normal);
		
		float angle = rand_value * 2.0 * PI * {roughness};
		float z = rand_value2 * {roughness};
		vec3 perturb_dir = vec3(
			cos(angle) * sqrt(1.0 - z*z),
			sin(angle) * sqrt(1.0 - z*z),
			z
		);
		mat3 TBN = mat3(uu, vv, normal);
		
		// Add base color contribution weighted by fresnel
		vec3 base_contribution = {base_color} * (1.0 - fresnel * {reflection_strength});
		ALBEDO += base_contribution;
		
		// Continue with reflection
		vec3 R = reflect(current_rd, normal);
		current_rd = normalize(mix(R, TBN * perturb_dir, {roughness}));
		t += current_accuracy * 2.0;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;

		continue;
	}
	"""

func get_custom_map_name() -> String:
	return "map_reflective"

func get_custom_map_template() -> String:
	return """
float ${MAP_NAME}(vec3 p) {
	float final_distance = MAX_DISTANCE;
	${SHAPES_CODE}
	return final_distance;
}"""
