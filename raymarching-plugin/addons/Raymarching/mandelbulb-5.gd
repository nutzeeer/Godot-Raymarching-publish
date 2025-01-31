# mandelbulb.gd
class_name Mandelbulb5
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 20.0},
	{"name": "iterations2", "type": TYPE_INT, "default": 15, "min": 1, "max": 50},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0},
	{"name": "detail_scale", "type": TYPE_FLOAT, "default": 0.5, "min": 0.01, "max": 2.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations2"),
		get_parameter_name("bailout"),
		get_parameter_name("detail_scale")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_optimized(vec3 p, float power, int max_iterations2, float bailout, float detail_scale) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	
	// Auto-detected detail parameters
	float dist_factor = smoothstep(10.0, 50.0, length(p)); // Distance-based LOD
//int dynamic_iterations = int((float(max_iterations) * (1.0 - dist_factor)) + ((float(max_iterations) / 4.0) * dist_factor));	
float dynamic_bailout = mix(bailout, bailout*1.5, dist_factor);
	
	// Core iteration loop with auto-bailing
	for (int i = 0; i < 100; i++) { // Fixed upper limit for GPU compatibility
		if (i >= max_iterations2) break;
		
		r = length(z);
		if (r > dynamic_bailout) break;

		// Polar coordinates conversion
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr = pow(r, power-1.0)*power*dr + 1.0;

		// Scaled coordinates
		float zr = pow(r, power);
		theta *= power;
		phi *= power;

		// Cartesian conversion
		z = zr*vec3(sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta));
		z += p;
	}

	// Adaptive distance estimation
	float base_estimate = 0.5 * log(r) * r / dr;
	return base_estimate * mix(detail_scale, detail_scale*0.5, dist_factor);
}
""" % id
