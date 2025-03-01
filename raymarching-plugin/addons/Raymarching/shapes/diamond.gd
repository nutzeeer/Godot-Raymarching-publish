# diamond_cut.gd
class_name DiamondCut
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR3, "default": Vector3.ONE, "min": 0.0001},
	{"name": "facets", "type": TYPE_INT, "default": 4, "min": 1, "max": 16},
	{"name": "roundness", "type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_diamond_cut(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("facets"),
		get_parameter_name("roundness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_diamond_cut(vec3 p, vec3 size, int facets, float roundness) {
	// Base box
	vec3 q = abs(p) - size;
	float box_dist = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
	
	// Create facets by modifying the distance based on angle
	float facet_angle = 6.28318 / float(facets);
	float angle = atan(p.z, p.x);
	
	// Normalize angle to the facet range
	float facet_id = floor((angle + 3.14159) / facet_angle);
	float facet_center = facet_angle * facet_id - 3.14159 + facet_angle * 0.5;
	
	// Add facet displacement
	float facet_factor = 1.0 - (cos(angle - facet_center) * 0.5 + 0.5);
	float facet_depth = length(p.xz) * 0.1 * (float(facets) / 4.0);
	float facet_dist = box_dist - facet_depth * facet_factor;
	
	// Apply y-axis diamond cuts (top and bottom)
	float y_angle = atan(length(p.xz), p.y);
	float y_facet_id = floor((y_angle + 1.57079) / facet_angle);
	float y_facet_center = facet_angle * y_facet_id - 1.57079 + facet_angle * 0.5;
	
	float y_facet_factor = 1.0 - (cos(y_angle - y_facet_center) * 0.5 + 0.5);
	float y_facet_depth = length(vec2(length(p.xz), p.y)) * 0.1 * (float(facets) / 4.0);
	
	// Combine horizontal and vertical facets
	float result = min(facet_dist, box_dist - y_facet_depth * y_facet_factor);
	
	// Apply roundness
	result -= roundness;
	
	return result;
}
	""" % id
