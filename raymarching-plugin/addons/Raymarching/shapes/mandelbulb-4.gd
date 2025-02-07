# mandelbulb.gd
class_name Mandelbulb4
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "power", "type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 20.0},
	{"name": "iterations", "type": TYPE_INT, "default": 15, "min": 1, "max": 50},
	{"name": "bailout", "type": TYPE_FLOAT, "default": 2.0, "min": 1.0, "max": 10.0},
	{"name": "detail_scale", "type": TYPE_FLOAT, "default": 0.5, "min": 0.01, "max": 2.0},
	{"name": "detail_growth", "type": TYPE_FLOAT, "default": 1.0, "min": 0.01, "max": 5.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("power"),
		get_parameter_name("iterations"),
		get_parameter_name("bailout"),
		get_parameter_name("detail_scale"),
		get_parameter_name("detail_growth")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_mandelbulb(vec3 p, float power, int iterations, float bailout, float detail_scale, float detail_growth) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	
	float dr_threshold = 1e5 / detail_growth;
	
	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > bailout) break;
		// Early termination when derivative gets too large
		if (dr > dr_threshold) break;
		
		// Convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr = pow(r, power - 1.0) * power * dr + detail_growth;
		
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
	
	float result = detail_scale * log(r) * r / dr;
	return result;
}
""" % id
