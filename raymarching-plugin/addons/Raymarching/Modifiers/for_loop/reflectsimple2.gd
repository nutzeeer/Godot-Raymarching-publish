# reflection_modifier.gd
class_name ReflectionModifier22
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "roughness",
		"type": TYPE_FLOAT,
		"default": 0.0,
		"min": 0.0,
		"max": 1.0,
		"description": "Surface roughness (0 = mirror, 1 = diffuse)"
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
		"name": "reflection_distance",
		"type": TYPE_FLOAT,
		"default": 100.0,
		"min": 0.1,
		"max": 1000.0,
		"description": "Maximum reflection trace distance"
	},
	{
		"name": "max_reflection_steps",
		"type": TYPE_INT,
		"default": 100,
		"min": 1,
		"max": 500,
		"description": "Maximum steps for reflection trace"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_utility_functions() -> String:
	return """
	// Random hash function for roughness
	float hash(vec2 p) {
		return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
	}
	
	// Create perturbed reflection direction based on roughness
	vec3 get_rough_reflection(vec3 R, vec3 N, float roughness, vec2 seed) {
		if (roughness <= 0.0) return R;
		
		// Create orthonormal basis
		vec3 uu = normalize(cross(N, vec3(0.0, 1.0, 1.0)));
		vec3 vv = cross(uu, N);
		
		// Calculate random perturbation
		float angle = hash(seed) * 2.0 * PI * roughness;
		float z = hash(seed.yx) * roughness;
		
		vec3 perturb_dir = vec3(
			cos(angle) * sqrt(1.0 - z*z),
			sin(angle) * sqrt(1.0 - z*z),
			z
		);
		
		// Build TBN matrix and mix between perfect and rough reflection
		mat3 TBN = mat3(uu, vv, N);
		return normalize(mix(R, TBN * perturb_dir, roughness));
	}
	"""

func get_forloop_modifier_template() -> String:
	return """
	// Check for reflection
	float f = map_reflective2(pos);
	if (f < current_accuracy) {
		hit = true;
		// Calculate view and reflection vectors
		vec3 V = normalize(ray_origin - pos);
		vec3 N = getNormal(pos);
		vec3 R = reflect(-V, N);
		
		// Calculate roughness perturbation
		vec3 rough_R = get_rough_reflection(R, N, {roughness}, SCREEN_UV);
		
		// Calculate Fresnel
		float NdotV = max(dot(N, V), 0.0);
		float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - NdotV, {fresnel_power});
		
		// Set up reflection ray
		vec3 reflection_ro = pos + N * current_accuracy * 3.0;
		float rt = current_accuracy * 3.0;
		
		// Update ray parameters for reflection
		ray_origin = reflection_ro;
		current_rd = rough_R;
		t = rt;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;
		
		// Check step limit
		if (i >= {max_reflection_steps}) {
			break;
		}
		
		continue;
	}
	"""

func get_color_modifier_template() -> String:
	return """
	// Modify color based on reflection properties
	float NdotV = max(dot(hit_normal, normalize(ray_origin - hit_pos)), 0.0);
	float fresnel = 0.04 + (1.0 - 0.04) * pow(1.0 - NdotV, {fresnel_power});
	ALBEDO = mix(ALBEDO, hit_normal * 0.5 + 0.5, fresnel);
	"""

func get_custom_map_name() -> String:
	return "map_reflective2"



# These return empty since we handle everything in the for loop
func get_d_modifier_template() -> String:
	return ""

func get_p_modifier_template() -> String:
	return ""
