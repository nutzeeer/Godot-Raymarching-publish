# capsule.gd
class_name Capsule
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "height", "type": TYPE_FLOAT, "default": 2.0, "min": 0.0001}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# capsule.gd
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_capsule(local_p, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("height")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
	float sdf_shape%s_capsule(vec3 p, float radius, float height) {
		// Create end points of the capsule's central line segment
		vec3 a = vec3(0.0, -height, 0.0);
		vec3 b = vec3(0.0, height, 0.0);
		
		// Get nearest point on line segment a-b
		vec3 ab = b - a;
		vec3 ap = p - a;
		float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
		vec3 nearest = a + t * ab;
		
		// Return distance to line segment minus radius
		float result = length(p - nearest) - radius;
		return result;
	}
	""" % id
