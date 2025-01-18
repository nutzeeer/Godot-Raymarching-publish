# spreading_copies.gd
class_name SpreadingCopies
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 0.5, "min": 0.0001},
	{"name": "time", "type": TYPE_FLOAT, "default": 0.0},
	{"name": "spread_speed", "type": TYPE_FLOAT, "default": 1.0, "min": 0.1}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_spreading_copies(local_p, %s, %s, %s)" % [
		id, 
		get_parameter_name("radius"),
		get_parameter_name("time"),
		get_parameter_name("spread_speed")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_spreading_copies(vec3 p, float radius, float time, float spread_speed) {
	// Calculate which copy this point is closest to (0 = original, 1 = first copy, etc.)
	float copy_index = floor(abs(p.y) / 4.0);
	
	// Each copy moves faster based on its index
	float speed_multiplier = 1.0 + copy_index * spread_speed;
	
	// Create position for this copy
	vec3 copy_p = p;
	copy_p.y = mod(p.y + time * speed_multiplier, 4.0) - 2.0;
	
	// Base sphere at modified position
	float d = length(copy_p) - radius;
	
	return d;
}
""" % id
