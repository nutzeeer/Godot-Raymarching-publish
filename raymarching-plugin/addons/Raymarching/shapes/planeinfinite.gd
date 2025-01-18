# planeinfinite.gd
class_name InfinitePlane
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "height", "type": TYPE_FLOAT, "default": 0.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# planeinfinite.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_infinite_plane(local_p, %s)" % [
		id,
		get_parameter_name("height")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_infinite_plane(vec3 p, float height) {
	// Core calculation
	float result = p.y - height;
	return result;
}
	""" % id
