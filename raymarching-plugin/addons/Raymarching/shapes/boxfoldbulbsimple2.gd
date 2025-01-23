# box_fold_bulb.gd
class_name BoxFoldBulbsimple2
extends ShapeBase

const SHAPE_PARAMETERS = [
	# Core Mandelbulb parameters
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 1, "max": 50},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0},
	{"name": "detail_scale", "type": TYPE_FLOAT, "default": 0.5, "min": 0.01, "max": 2.0},
	{"name": "detail_growth", "type": TYPE_FLOAT, "default": 1.0, "min": 0.01, "max": 5.0},
	# Box fold specific parameters
	{"name": "scale_a1", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 2.0},
	{"name": "scale_neg1", "type": TYPE_FLOAT, "default": 1.0, "min": -2.0, "max": 2.0},
	{"name": "offset", "type": TYPE_VECTOR3, "default": Vector3(2.0, 2.0, 2.0)},
	{"name": "alpha_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "beta_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "fold_start", "type": TYPE_INT, "default": 0, "min": 0, "max": 50},
	{"name": "fold_end", "type": TYPE_INT, "default": 0, "min": 0, "max": 50}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_box_fold_bulb(local_p, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("bailout"),
		get_parameter_name("detail_scale"),
		get_parameter_name("detail_growth"),
		get_parameter_name("scale_a1"),
		get_parameter_name("scale_neg1"),
		get_parameter_name("offset"),
		get_parameter_name("alpha_angle"),
		get_parameter_name("beta_angle"),
		get_parameter_name("fold_start"),
		get_parameter_name("fold_end")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_box_fold_bulb(vec3 p, float power, int iterations, float bailout, 
	float detail_scale, float detail_growth, float scale_a1, float scale_neg1, 
	vec3 offset222, float alpha_angle, float beta_angle, 
	int fold_start, int fold_end) {
	
	vec3 z = p;
	float dr = 1.0;
	float prev_dr = dr;
	float r = 0.0;
	
	float dr_threshold = 1e5 / detail_growth;
	float growth_threshold = 1e3;
	float exponential_factor = 1e2;
	
	for(int i = 0; i < iterations; i++) {
		r = length(z);
		
		if (r > bailout) break;
		if (dr > dr_threshold) break;
		
		float dr_growth = dr / prev_dr;
		if (dr_growth > growth_threshold) break;
		if (dr > r * exponential_factor) break;
		if (dr > pow(10.0, power)) break;
		
		prev_dr = dr;
		
		// Box folding
		z.x = abs(z.x + offset222.x) - abs(z.x - offset222.x) - z.x;
		z.y = abs(z.y + offset222.y) - abs(z.y - offset222.y) - z.y;
		
		if(i >= fold_start && i < fold_end) {
			z.z = abs(z.z + offset222.z) - abs(z.z - offset222.z) - z.z;
		}
		
		z *= scale_a1;
		dr *= abs(scale_a1);
		
		r = length(z);
		if (r < 1e-21) r = 1e-21;
		
		float theta = asin(z.z/r) + beta_angle;
		float phi = atan(z.y, z.x) + alpha_angle;
		
		dr = pow(r, power - 1.0) * power * dr + detail_growth;
		
		float zr = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		
		z = zr * vec3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta)
		);
		z.z *= scale_neg1;
		z += p;
	}
	
	float result = detail_scale * log(r) * r / dr;
	return result;
}
""" % id
