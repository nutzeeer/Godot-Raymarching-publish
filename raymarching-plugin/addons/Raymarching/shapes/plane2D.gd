# plane_2d.gd
class_name Plane2D1
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR2, "default": Vector2(10.0, 10.0), "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_plane2d(local_p, %s)" % [
		id,
		get_parameter_name("size")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_plane2d(vec3 p, vec2 size) {
	// Core calculation
	vec2 d = abs(p.xz) - size;  // Distance in XZ plane from rectangle bounds
	float plane_dist = length(max(d, 0.000001)) + min(max(d.x, d.y), 0.0);  // XZ distance
	float height_dist = abs(p.y);  // Distance from XY plane
	float result = max(plane_dist, height_dist);  // Combine using max for sharp boundary
	return result;
}
	""" % id
