# mandelbulb.gd
class_name MandelbulbSpherical
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": -8.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 0, "max": 50},
	{"name": "symmetry", "type": TYPE_FLOAT, "default": 3.0, "min": 0.1, "max": 10.0},
	{"name": "convergence", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 2.0},
	{"name": "scale", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 5.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("symmetry"),
		get_parameter_name("convergence"),
		get_parameter_name("scale")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_mandelbulb(vec3 p, float power, int iterations, float symmetry, float convergence, float scale) {
	if (iterations <= 0) {
		return length(p) - 1.0;  // Default to sphere if no iterations
	}

	vec3 z = p;
	float dr = 1.0;
	float r = length(z);
	
	for(int i = 0; i < iterations; i++) {
		// Pre-calculate r squared and its inverse to avoid division
		float r2 = r * r;
		float inv_r2 = 1.0 / r2;
		
		// Calculate derivatives first
		dr = power * pow(r, power - 1.0) * dr * convergence + 1.0;
		
		// Calculate the harmonics with symmetry
		float x2 = z.x * z.x * symmetry * inv_r2;
		float y2 = z.y * z.y * symmetry * inv_r2;
		float z2 = z.z * z.z * symmetry * inv_r2;
		
		// Update position
		float zr = pow(r, power) * scale;
		z = zr * vec3(
			z.x * (3.0 * x2 - 1.0),
			z.y * (3.0 * y2 - 1.0),
			z.z * (3.0 * z2 - 1.0)
		) + p;
		
		r = length(z);
		
		// Early break if we're getting too far out
		if (r > 2.0) break;
	}
	
	return 0.5 * r * log(r) / dr;
}
""" % id
