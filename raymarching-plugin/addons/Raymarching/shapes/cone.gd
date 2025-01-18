# cone.gd
class_name Cone
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "height", "type": TYPE_FLOAT, "default": 2.0, "min": 0.0001},
	{"name": "roundness", "type": TYPE_FLOAT, "default": 0.001, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# cone.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_cone(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("height"),
		get_parameter_name("roundness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
	float sdf_shape%s_cone(vec3 p, float radius, float height, float roundness) {
		// Core calculation
		vec2 q = vec2(length(p.xz), p.y);
		vec2 tip = vec2(radius, height);
		vec2 a = q - tip * clamp(dot(q, tip) / dot(tip, tip), 0.0, 1.0);
		float result = length(a) - roundness;
		return result;
	}
	""" % id
