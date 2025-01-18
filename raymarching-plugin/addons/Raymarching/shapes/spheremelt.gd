# melting_sphere.gd
class_name MeltingSphere
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "melt", "type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 1.0},
	{"name": "drip_speed", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 5.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_melting_sphere(local_p, %s, %s, %s)" % [
		id, 
		get_parameter_name("radius"),
		get_parameter_name("melt"),
		get_parameter_name("drip_speed")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_melting_sphere(vec3 p, float radius, float melt, float drip_speed) {
	// Create a downward-flowing displacement field
	float flow = p.y + sin(p.x * drip_speed) * 0.3 + sin(p.z * drip_speed) * 0.3;
	
	// Smooth step for controlled melting transition
	float melt_factor = smoothstep(0.0, -2.0, flow);
	
	// Apply melting displacement to y-coordinate
	vec3 melted_p = p;
	melted_p.y += melt_factor * melt * 2.0;
	
	// Calculate base sphere with smooth melting transition
	float sphere = length(melted_p) - radius;
	
	// Add drip detail
	float drips = sin(p.x * 2.0) * sin(p.z * 2.0) * smoothstep(-1.0, 0.0, flow) * melt * 0.1;
	
	return sphere + drips;
}
""" % id
