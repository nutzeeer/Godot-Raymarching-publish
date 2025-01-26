class_name Plane2D
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR2, "default": Vector2(10.0, 10.0), "min": 0.0001},
	{"name": "curvature", "type": TYPE_FLOAT, "default": 0.0, "min": -1.0, "max": 1.0},
	{"name": "thickness", "type": TYPE_FLOAT, "default": 0.1, "min": 0.0001, "max": 1.0},
	{"name": "roundness", "type": TYPE_FLOAT, "default": 0.001, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_plane2d(local_p, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("curvature"),
		get_parameter_name("thickness"),
		get_parameter_name("roundness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_plane2d(vec3 p, vec2 size, float curvature, float thickness, float roundness) {
	// Calculate distance to bounds in XZ plane
	vec2 d = abs(p.xz) - size;
	float plane_dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
	
	// Calculate curved surface distance with thickness
	float curve = curvature * p.x * p.x;
	float height_dist = abs(p.y - curve) - thickness;
	
	// Combine distances with roundness
	float result = length(max(vec2(plane_dist, height_dist), 0.0)) + 
				  min(max(plane_dist, height_dist), 0.0) - roundness;
	
	return result;
}
""" % id
