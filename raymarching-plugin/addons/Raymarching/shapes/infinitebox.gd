# plane.gd
class_name infinitepillar
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR2, "default": Vector2(1.0, 1.0), "min": 0.0001},
	{"name": "blend", "type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_infpillar(local_p, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("blend")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
	float sdf_shape%s_infpillar(vec3 p, vec2 size, float blend) {
		// Core calculation
		float height = p.y;
		float edge_x = abs(p.x) - size.x;
		float edge_z = abs(p.z) - size.y;
		float edge_dist = length(max(vec2(edge_x, edge_z), 0.0));
		
		// Blend between sharp and smooth transition at edges
		float result = mix(
			max(height, edge_dist),  // Sharp edges
			sqrt(height * height + edge_dist * edge_dist),  // Smooth edges
			blend
		);
	return result;
	}
	""" % id
