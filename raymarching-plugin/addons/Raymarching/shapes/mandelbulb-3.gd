# mandelbulb.gd
class_name Mandelbulb3
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 1, "max": 50},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0},
	{"name": "detail_multiplier", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 5.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s, %s, current_accuracy)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("bailout"),
		get_parameter_name("detail_multiplier")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_mandelbulb(vec3 p, float power, int iterations, float bailout, float detail_multiplier, float pixel_accuracy) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	
	// Early bail if clearly outside the bounding sphere
	float bound = length(p);
	if (bound > bailout * 1.5) {
		return bound * 0.5;
	}
	
	// Adjust iterations based on distance and pixel accuracy
	float dist_scale = length(p);
	float accuracy_scale = 1.0 / (1.0 + pixel_accuracy * 100.0);
	int dynamic_iterations = int(float(iterations) * accuracy_scale / (1.0 + dist_scale * 0.1));
	dynamic_iterations = max(dynamic_iterations, iterations / 4);
	
	// Adjust dr increment based on pixel accuracy
	float dr_increment = 1.0 + pixel_accuracy * detail_multiplier;
	
	for (int i = 0; i < dynamic_iterations; i++) {
		r = length(z);
		if (r > bailout) break;
		
		// Convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr = pow(r, power - 1.0) * power * dr + dr_increment;
		
		// Scale and rotate the point
		float zr = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		
		// Convert back to cartesian coordinates
		z = zr * vec3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta)
		);
		z += p;
	}
	
	// Distance estimation with accuracy-aware detail control
	float base_dist = 0.5 * log(r) * r / dr;
	float accuracy_adjusted_dist = base_dist * (1.0 + pixel_accuracy * 5.0);
	return accuracy_adjusted_dist * detail_multiplier;
}
""" % id
