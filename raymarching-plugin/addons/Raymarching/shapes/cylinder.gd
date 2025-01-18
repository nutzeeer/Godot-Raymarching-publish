# cylinder.gd
class_name Cylinder
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "height", "type": TYPE_FLOAT, "default": 2.0, "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# cylinder.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_cylinder(local_p, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("height")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_cylinder(vec3 p, float radius, float height) {
	// Core calculation
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(radius, height);
	float result = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
	return result;
}
	""" % id
