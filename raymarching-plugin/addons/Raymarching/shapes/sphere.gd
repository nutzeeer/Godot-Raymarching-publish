# sphere.gd
class_name Sphere
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# sphere.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_sphere(local_p, %s)" % [id, get_parameter_name("radius")]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_sphere(vec3 p, float radius) {
	// Core calculation
	float result = length(p) - radius;
	return result;
	}
	""" % id
