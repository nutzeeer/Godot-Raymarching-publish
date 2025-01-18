# broken_cube.gd
class_name BrokenCube
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "size", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "distortion", "type": TYPE_FLOAT, "default": 0.2, "min": 0.0, "max": 0.5},  # Reduced range
	{"name": "pulse_speed", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 5.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_broken_cube(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("size"),
		get_parameter_name("distortion"),
		get_parameter_name("pulse_speed")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_broken_cube(vec3 p, float size, float distortion, float pulse_speed) {
	// Start with a basic box distance
	vec3 q = abs(p) - vec3(size);
	float base = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
	
	// Add some controlled distortion
	float wave = sin(p.x * pulse_speed) * sin(p.y * pulse_speed) * sin(p.z * pulse_speed);
	
	// Break the distance field in a more controlled way
	return base + wave * distortion * size;
}
""" % id
