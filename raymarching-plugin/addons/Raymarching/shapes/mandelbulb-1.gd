# mandelbulb.gd
class_name Mandelbulb1
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 3.0, "min": 0.1, "max": 10.0},
	{"name": "fold_count", "type": TYPE_FLOAT, "default": 12.5, "min": 1.0, "max": 16.0},
	{"name": "smoothness", "type": TYPE_FLOAT, "default": 0.8, "min": 0.01, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_mandelbulb(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("fold_count"),
		get_parameter_name("smoothness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_mandelbulb(vec3 p, float radius, float fold_count, float smoothness) {
	vec3 z = p;
	float r = length(z);
	
	// Basic spherical folding
	float theta = acos(z.z/max(r, 0.0001));
	float phi = atan(z.y, z.x);
	
	// Create the bulb effect using spherical coordinates
	float bulb = r - radius + sin(theta * fold_count) * smoothness + cos(phi * fold_count) * smoothness;
	
	float result = bulb;
	return result;
}
""" % id
