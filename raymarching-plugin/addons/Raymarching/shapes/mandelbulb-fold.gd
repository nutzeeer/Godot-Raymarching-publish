# mandelbulb.gd
class_name Mandelbulbfold
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
	
	for(int i = 0; i < iterations; i++) {
		// Fold space
		z.xy = abs(z.xy);
		if(z.x < z.y) z.xy = z.yx;
		if(z.x < z.z) z.xz = z.zx;
		if(z.y < z.z) z.yz = z.zy;
		
		// Scale and rotate
		r = length(z);
		if(r > bailout) break;
		
		float multiplier = power * pow(r, power-1.0);
		dr = dr * multiplier + 1.0;
		z = multiplier * z + p;
	}
	
	float result = 0.5 * log(r) * r / dr;
	return result;
}
""" % id
