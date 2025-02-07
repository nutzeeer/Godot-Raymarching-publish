# mandelbulb.gd
class_name Mandelbulb22
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": -8.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 0, "max": 50},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("bailout")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
// Helper function to compute both sin and cos simultaneously
vec2 sin_cos(float angle) {
	return vec2(sin(angle), cos(angle));
}

float sdf_shape%s_mandelbulb(vec3 p, float power, int iterations, float bailout) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	const float dr_threshold = 1e10;
	float power_minus_1 = power - 1.0;  // Precompute once
	
	// Early escape using iterative series approximation
	float initial_r = length(p);
	if (initial_r > 4.0) {  // Empirical threshold for common bailouts
		return 0.5 * log(initial_r) * initial_r / 1.0;
	}

	for (int i = 0; i < iterations; i++) {
		r = length(z);
		
		// Early exit priority: Most likely first
		if (r > bailout || dr > dr_threshold) break;
		
		// Optimized reciprocal with safety
		float inv_r = 1.0 / max(r, 1e-21);
		
		// Combined power operations
		float zr = pow(r, power);
		dr = zr * inv_r * power * dr + 1.0;  // Replaces pow(r, power-1)
		
		// Vectorized trigonometry
		vec2 theta = sin_cos(acos(z.z * inv_r) * power);
		vec2 phi = sin_cos(atan(z.y, z.x) * power);
		
		// Optimized coordinate calculation
		z = zr * vec3(
			theta.x * phi.y,  // sin(theta)*cos(phi)
			theta.x * phi.x,  // sin(theta)*sin(phi)
			theta.y           // cos(theta)
		);
		
		z += p;
		
		// Orbit detection using relative movement
		if (i > 4 && length(z - p) < 1e-5 * initial_r) break;
	}
	
	return 0.5 * log(max(r, 1e-10)) * r / max(dr, 1e-10);
}
""" % id
