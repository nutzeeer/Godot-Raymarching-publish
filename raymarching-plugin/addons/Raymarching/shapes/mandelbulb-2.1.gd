# mandelbulb.gd
class_name Mandelbulb21
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
float sdf_shape%s_mandelbulb(vec3 p, float power, int iterations, float bailout) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	const float dr_threshold = 1e10; // Early exit when DR grows too large

	
	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > bailout) break;
		
		// Convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr = pow(r, power - 1.0) * power * dr + 1.0;
		
		// Stop if distance estimate becomes irrelevant
		if (dr > dr_threshold) break;
		
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
	
	// Distance estimation
	float result = 0.5 * log(r) * r / dr;
	return result;
}
""" % id
