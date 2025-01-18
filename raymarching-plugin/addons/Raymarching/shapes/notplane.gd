# plane.gd
class_name notRMPlane
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR2, "default": Vector2(1.0, 1.0), "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# plane.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_plane(local_p, %s)" % [
		id,
		get_parameter_name("size")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_plane(vec3 p, vec2 size) {
	// Core calculation
	vec2 d = abs(p.xz) - size;
	float result = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) + abs(p.y);
	return result;
}
	""" % id
