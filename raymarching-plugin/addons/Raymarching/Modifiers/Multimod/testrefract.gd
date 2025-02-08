# refraction_modifier.gd
class_name RefractionModifiertest
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "refractive_index_outer",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 1.0,
		"max": 2.0,
		"description": "Refractive index of the surrounding medium"
	},
	{
		"name": "refractive_index_inner",
		"type": TYPE_FLOAT,
		"default": 1.33,
		"min": 1.0,
		"max": 2.0,
		"description": "Refractive index of the object medium"
	},
	{
		"name": "absorption",
		"type": TYPE_VECTOR3,
		"default": Vector3(0.02, 0.02, 0.02),
		"description": "Light absorption coefficients per channel"
	},
	{
		"name": "reflectivity",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 1.0,
		"description": "Base surface reflectivity"
	},
	{
		"name": "specularity",
		"type": TYPE_FLOAT,
		"default": 100.0,
		"min": 0.0,
		"max": 1000.0,
		"description": "Specular highlight exponent"
	},
	{
		"name": "use_fresnel",
		"type": TYPE_BOOL,
		"default": true,
		"description": "Enable Fresnel reflectance"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_utility_functions() -> String:
	return """
// Schlick's Fresnel approximation
float fresnel(vec3 normal, vec3 incident, float n1, float n2) {
	float r0 = pow((n1-n2)/(n1+n2), 2.0);
	float cos_theta = -dot(normal, incident);
	if (n1 > n2) {
		float n = n1/n2;
		float sin_t2 = n*n*(1.0 - cos_theta*cos_theta);
		if (sin_t2 > 1.0) return 1.0;
		cos_theta = sqrt(1.0 - sin_t2);
	}
	float x = 1.0 - cos_theta;
	return r0 + (1.0 - r0) * pow(x, 5.0);
}

vec3 refract(vec3 incident, vec3 normal, float eta) {
	float k = 1.0 - eta*eta*(1.0 - dot(normal, incident)*dot(normal, incident));
	return k < 0.0 ? vec3(0.0) : eta*incident - (eta*dot(normal, incident) + sqrt(k))*normal;
}
"""

func get_color_modifier_template() -> String:
	return """
	// Refraction surface interaction
	vec3 view_dir = -current_rd;
	float fresnel_amount = {reflectivity};
	
	if ({use_fresnel}) {
		fresnel_amount = fresnel(hit_normal, view_dir, 
			{refractive_index_outer}, {refractive_index_inner});
	}
	
	// Calculate reflection
	vec3 reflect_dir = reflect(view_dir, hit_normal);
	vec3 reflect_col = getEnvironmentColor(reflect_dir);
	
	// Calculate refraction
	vec3 refract_dir = refract(view_dir, hit_normal, 
		{refractive_index_outer}/{refractive_index_inner});
	vec3 refract_col = getEnvironmentColor(refract_dir);
	
	// Apply absorption (simplified travel distance)
	float travel_distance = length(hit_pos - current_ro);
	vec3 absorb = exp(-{absorption} * travel_distance);
	refract_col *= absorb;
	
	// Combine results
	ALBEDO = mix(refract_col, reflect_col, fresnel_amount);
	
	// Add specular highlight
	vec3 light_dir = normalize(vec3(1.0,2.0,1.0));
	vec3 half_vec = normalize(light_dir + view_dir);
	float spec = pow(max(dot(hit_normal, half_vec), 0.0), {specularity});
	ALBEDO += vec3(spec) * 0.5;
	"""

func get_forloop_modifier_template() -> String:
	return """
	// Volumetric absorption (inside medium)
	if (is_inside) {
		current_color *= exp(-{absorption} * d_step);
	}
	"""

func get_pre_map_functions() -> String:
	return """
// Track medium entry/exit points
vec3 entry_pos;
bool is_inside = false;

void update_medium_state(vec3 pos) {
	if (hit_normal != vec3(0.0)) {
		if (!is_inside) entry_pos = pos;
		is_inside = !is_inside;
	}
}
"""
