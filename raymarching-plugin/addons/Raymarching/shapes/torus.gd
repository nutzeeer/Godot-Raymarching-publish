# torus.gd
class_name Torus
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "thickness", "type": TYPE_FLOAT, "default": 0.25, "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# torus.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_torus(local_p, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("thickness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_torus(vec3 p, float radius, float thickness) {
	// Core calculation
	vec2 q = vec2(length(p.xz) - radius, p.y);
	float result = length(q) - thickness;
	return result;
}
	""" % id
