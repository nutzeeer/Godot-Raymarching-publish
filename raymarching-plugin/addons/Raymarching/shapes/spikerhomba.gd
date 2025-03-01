# diamond_cut.gd
class_name spikerhomba
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_VECTOR3, "default": Vector3.ONE, "min": 0.0001},
	{"name": "iterations", "type": TYPE_INT, "default": 3, "min": 1, "max": 6},
	{"name": "split_factor", "type": TYPE_FLOAT, "default": 0.5, "min": 0.1, "max": 0.9},
	{"name": "roundness", "type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_spike(local_p, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("iterations"),
		get_parameter_name("split_factor"),
		get_parameter_name("roundness")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_spike(vec3 p, vec3 size, int iterations, float split_factor, float roundness) {
	// Start with base octahedron shape
	vec3 q = abs(p);
	float base_dist = (q.x + q.y + q.z - size.x) * 0.57735027;
	
	// Apply iterative facets
	vec3 pos = p;
	float scale = 1.0;
	float detail = 0.0;
	
	for (int i = 0; i < iterations; i++) {
		// Skip if beyond our iteration count
		if (i >= iterations) break;
		
		// Fold space to create facets
		pos = abs(pos);
		if (pos.x < pos.y) pos.xy = pos.yx;
		if (pos.x < pos.z) pos.xz = pos.zx;
		if (pos.y < pos.z) pos.yz = pos.zy;
		
		// Stretching transformation
		pos = pos * split_factor - size * (split_factor - 1.0);
		
		// Scale space for next iteration
		scale *= split_factor;
		
		// Accumulate detail from each iteration
		float iteration_contribution = pow(0.5, float(i));
		detail += (length(pos) - length(size)) * iteration_contribution;
	}
	
	// Combine base shape with iterative detail
	float final_dist = base_dist - detail * 0.2;
	
	// Apply roundness
	final_dist -= roundness;
	
	return final_dist;
}
	""" % id
