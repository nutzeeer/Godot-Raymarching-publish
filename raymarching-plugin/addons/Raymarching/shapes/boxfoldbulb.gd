# box_fold_bulb.gd
class_name BoxFoldBulb 
extends ShapeBase

const SHAPE_PARAMETERS = [
	# Core Mandelbulb parameters
	{"name": "power", "type": TYPE_FLOAT, "default": 9.0, "min": 1.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 250, "min": 0, "max": 250},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0},
	{"name": "detail_scale", "type": TYPE_FLOAT, "default": 0.5, "min": 0.01, "max": 2.0},
	{"name": "detail_growth", "type": TYPE_FLOAT, "default": 1.0, "min": 0.01, "max": 5.0},
	
	# Mandelbulb angle controls
	{"name": "theta_scale", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0},
	{"name": "phi_scale", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 10.0},
	{"name": "alpha_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "beta_angle", "type": TYPE_FLOAT, "default": 0.0, "min": -PI, "max": PI},
	{"name": "use_cos_mode", "type": TYPE_BOOL, "default": false},
	{"name": "enable_costh", "type": TYPE_BOOL, "default": false},
	{"name": "enable_sinth", "type": TYPE_BOOL, "default": false},
	
	# Box fold parameters per axis
	{"name": "fold_start_x", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "fold_end_x", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "fold_start_y", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "fold_end_y", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "fold_start_z", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "fold_end_z", "type": TYPE_INT, "default": 0, "min": 0, "max": 250},
	{"name": "offset", "type": TYPE_VECTOR3, "default": Vector3(2.0, 2.0, 2.0)},
	
	# Symmetry transformation controls
	{"name": "enable_sym4", "type": TYPE_BOOL, "default": false},
	{"name": "sym4_scale", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 2.0},
	{"name": "sym4_offset", "type": TYPE_VECTOR3, "default": Vector3.ZERO},
	
	# Final scaling and offset
	{"name": "scale_a1", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 2.0},
	{"name": "scale_neg1", "type": TYPE_FLOAT, "default": 1.0, "min": -2.0, "max": 2.0},
	{"name": "radial_offset", "type": TYPE_FLOAT, "default": 0.0, "min": -1.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_box_fold_bulb(local_p, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("bailout"),
		get_parameter_name("detail_scale"),
		get_parameter_name("detail_growth"),
		get_parameter_name("theta_scale"),
		get_parameter_name("phi_scale"),
		get_parameter_name("alpha_angle"),
		get_parameter_name("beta_angle"),
		get_parameter_name("use_cos_mode"),
		get_parameter_name("enable_costh"),
		get_parameter_name("enable_sinth"),
		get_parameter_name("fold_start_x"),
		get_parameter_name("fold_end_x"),
		get_parameter_name("fold_start_y"),
		get_parameter_name("fold_end_y"),
		get_parameter_name("fold_start_z"),
		get_parameter_name("fold_end_z"),
		get_parameter_name("offset"),
		get_parameter_name("enable_sym4"),
		get_parameter_name("sym4_scale"),
		get_parameter_name("sym4_offset"),
		get_parameter_name("scale_a1"),
		get_parameter_name("scale_neg1"),
		get_parameter_name("radial_offset")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_box_fold_bulb(vec3 p, float power, int iterations, float bailout, 
	float detail_scale, float detail_growth, float theta_scale, float phi_scale,
	float alpha_angle, float beta_angle, bool use_cos_mode, bool enable_costh, bool enable_sinth,
	int fold_start_x, int fold_end_x, int fold_start_y, int fold_end_y, 
	int fold_start_z, int fold_end_z, vec3 offset222,
	bool enable_sym4, float sym4_scale, vec3 sym4_offset,
	float scale_a1, float scale_neg1, float radial_offset) {
	
	vec3 z = p;
	float dr = 1.0;
	float r = length(z);
	
	for(int i = 0; i < iterations; i++) {
		// Apply box folding per axis based on iteration ranges
		if(i >= fold_start_x && i < fold_end_x)
			z.x = abs(z.x + offset222.x) - abs(z.x - offset222.x) - z.x;
		if(i >= fold_start_y && i < fold_end_y)
			z.y = abs(z.y + offset222.y) - abs(z.y - offset222.y) - z.y;
		if(i >= fold_start_z && i < fold_end_z)
			z.z = abs(z.z + offset222.z) - abs(z.z - offset222.z) - z.z;
		
		// Core mandelbulb transformation
		r = length(z);
		if(r > bailout) break;
		
		float theta = asin(z.z/r) + beta_angle;
		float phi = atan(z.y, z.x) + alpha_angle;
		
		dr = pow(r, power - 1.0) * power * dr + detail_growth;
		
		float zr = pow(r, power);
		theta = theta * power * theta_scale;
		phi = phi * power * phi_scale;
		
		float sin_theta = use_cos_mode ? (enable_sinth ? sin(theta) : cos(theta)) : sin(theta);
		float cos_theta = use_cos_mode ? (enable_costh ? cos(theta) : sin(theta)) : cos(theta);
		
		z = zr * vec3(
			cos_theta * cos(phi),
			cos_theta * sin(phi),
			sin_theta
		);
		
		// Apply sym4 transformation if enabled
		if(enable_sym4) {
			// Sort components
			if(abs(z.x) < abs(z.z)) z = vec3(z.z, z.y, z.x);
			if(abs(z.x) < abs(z.y)) z = vec3(z.y, z.x, z.z);
			if(abs(z.y) < abs(z.z)) z = vec3(z.x, z.z, z.y);
			
			// Sign adjustments
			if(z.x * z.z < 0.0) z.z = -z.z;
			if(z.x * z.y < 0.0) z.y = -z.y;
			
			vec3 temp;
			temp.x = z.x * z.x - z.y * z.y - z.z * z.z;
			temp.y = 2.0 * z.x * z.y;
			temp.z = 2.0 * z.x * z.z;
			
			z = temp * sym4_scale + sym4_offset;
		}
		
		z *= scale_a1;
		z.z *= scale_neg1;
		
		// Apply radial offset
		float len = length(z);
		if(len > 1e-21) {
			z *= (1.0 + radial_offset/len);
		}
		
		z += p;
	}
	
	float result = detail_scale * log(r) * r / dr;
	return result;
}
""" % id
