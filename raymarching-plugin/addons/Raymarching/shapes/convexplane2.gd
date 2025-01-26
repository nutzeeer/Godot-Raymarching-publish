class_name Plane2D3
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
	// Calculate distance to bounds in XZ plane
	vec2 d = abs(p.xz) - size;
	float plane_dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
	
	// Calculate curved height
	float curve = curvature * p.x * p.x;
	float height_dist = p.y - curve;
	
	// Determine if point is inside the bounds
	float inside = (plane_dist <= 0.0) ? -1.0 : 1.0;
	
	// Combine distances for final SDF, preserving sign
	float result = inside * length(vec2(max(plane_dist, 0.0), height_dist));
	
	return result;
}
""" % id
