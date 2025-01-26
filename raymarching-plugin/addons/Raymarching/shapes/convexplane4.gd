class_name Plane2D4
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR2, "default": Vector2(10.0, 10.0), "min": 0.0001},
	{"name": "curvature", "type": TYPE_FLOAT, "default": 0.0, "min": -1.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_plane2d(local_p, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("curvature")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_plane2d(vec3 p, vec2 size, float curvature) {
	// Calculate distance to XZ boundaries (rectangle)
	vec2 d = abs(p.xz) - size;
	float edge_dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
	
	// Calculate distance to curved surface (parabola y = kx²)
	float k = curvature / size.x; // Scale curvature relative to size.x
	float closest_x = clamp(p.x / (1.0 + 2.0 * k * p.y), -size.x, size.x); // Solve for closest point on parabola
	float curve_dist = p.y - k * closest_x * closest_x; // Vertical distance to curve
	
	// Combine distances: edge_dist (outside XZ bounds) vs. curve_dist (inside)
	return max(edge_dist, curve_dist);
}
""" % id
