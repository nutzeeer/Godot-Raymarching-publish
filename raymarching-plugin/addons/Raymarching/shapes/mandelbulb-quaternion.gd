# mandelbulb.gd
class_name Mandelbulbquaternion
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
 vec4 z = vec4(p, 0.0);  // Convert to quaternion (w component is 0)
	float dr = 1.0;
	float r = 0.0;
	vec4 c = z;

	for(int i = 0; i < iterations; i++) {
		r = length(z);
		if(r > bailout) break;

		// Quaternion multiplication
		float zr = pow(r, power-1.0);
		vec4 v = vec4(
			z.x*z.x - z.y*z.y - z.z*z.z + z.w*z.w,
			2.0*z.x*z.y,
			2.0*z.x*z.z,
			2.0*z.x*z.w
		);
		
		z = zr * v + c;
		dr = dr * power * zr;
	}
	float result = 0.5 * log(r) * r / dr;
	return result;
}
""" % id
