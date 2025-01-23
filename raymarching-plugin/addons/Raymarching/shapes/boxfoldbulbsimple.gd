# box_fold_bulb.gd
class_name BoxFoldBulbsimple
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "scale_a1", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 2.0},
	{"name": "scale2", "type": TYPE_FLOAT, "default": 8.0, "min": -8.0, "max": 12.0},
	{"name": "scale_neg1", "type": TYPE_FLOAT, "default": 1.0, "min": -2.0, "max": 2.0},
	{"name": "offset", "type": TYPE_VECTOR3, "default": Vector3(0.5, 0.5, 0.5)},
	{"name": "alpha_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "beta_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "fold_start", "type": TYPE_INT, "default": 0, "min": 0, "max": 50},
	{"name": "fold_end", "type": TYPE_INT, "default": 15, "min": 0, "max": 50},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 1, "max": 50},
	{"name": "de_scale", "type": TYPE_FLOAT, "default": 0.5, "min": 0.01, "max": 2.0},
	{"name": "de_offset", "type": TYPE_FLOAT, "default": 0.0, "min": -1.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_box_fold_bulb(local_p, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("scale_a1"),
		get_parameter_name("scale2"),
		get_parameter_name("scale_neg1"),
		get_parameter_name("offset"),
		get_parameter_name("alpha_angle"),
		get_parameter_name("beta_angle"),
		get_parameter_name("fold_start"),
		get_parameter_name("fold_end"),
		get_parameter_name("iterations"),
		get_parameter_name("de_scale"),
		get_parameter_name("de_offset")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_box_fold_bulb(vec3 p, float scale_a1, float scale2, float scale_neg1, 
	vec3 offset222, float alpha_angle, float beta_angle, 
	int fold_start, int fold_end, int max_iterations,
	float de_scale, float de_offset) {
	
	vec3 z = p;
	float dr = 1.0;
	float prev_dr = dr;
	float r = 0.0;
	
	// Add stability thresholds
	float dr_threshold = 1e5;
	float growth_threshold = 1e3;
	float exponential_factor = 1e2;
	
	for(int i = 0; i < max_iterations; i++) {
		r = length(z);
		
		// Add break conditions like Mandelbulb
		if (r > 2.0) break;  // Bailout
		if (dr > dr_threshold) break;
		
		float dr_growth = dr / prev_dr;
		if (dr_growth > growth_threshold) break;
		if (dr > r * exponential_factor) break;
		
		prev_dr = dr;
		
		// Box folding
		z.x = abs(z.x + offset222.x) - abs(z.x - offset222.x) - z.x;
		z.y = abs(z.y + offset222.y) - abs(z.y - offset222.y) - z.y;
		
		if(i >= fold_start && i < fold_end) {
			z.z = abs(z.z + offset222.z) - abs(z.z - offset222.z) - z.z;
		}
		
		z *= scale_a1;
		dr *= abs(scale_a1);
		
		float r = length(z);
		if (r < 1e-21) r = 1e-21;  // Prevent division by zero
		
		float theta = asin(z.z/r) + beta_angle;
		float phi = atan(z.y, z.x) + alpha_angle;
		
		float rp = pow(r, scale2 - 1.0);
		float theta_new = theta * scale2;
		float phi_new = phi * scale2;
		
		float cos_theta = cos(theta_new);
		rp *= r;
		
		z.x = cos_theta * cos(phi_new) * rp;
		z.y = cos_theta * sin(phi_new) * rp;
		z.z = sin(theta_new) * rp;
		
		z.z *= scale_neg1;
		dr = dr * abs(scale2) * rp;
	}
	
	// Use logarithmic distance estimation like Mandelbulb
	float result = de_scale * log(r) * r / dr;
	return result + de_offset;
}
""" % id
