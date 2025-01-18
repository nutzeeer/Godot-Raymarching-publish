# box.gd
class_name sinBox
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR3, "default": Vector3.ONE, "min": 0.0001},
	{"name": "roundness", "type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# box.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_box(local_p, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("roundness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_box(vec3 p, vec3 size, float roundness) {
	// Core calculation
	vec3 q = sin(p) - size;
	float result = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - roundness;
	return result;
}
	""" % id
