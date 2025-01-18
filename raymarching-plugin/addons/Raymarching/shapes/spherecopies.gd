# falling_copies.gd
class_name FallingCopies
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 0.5, "min": 0.0001},
	{"name": "time", "type": TYPE_FLOAT, "default": 0.0},
	{"name": "spacing", "type": TYPE_FLOAT, "default": 4.0, "min": 1.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_falling_copies(local_p, %s, %s, %s)" % [
		id, 
		get_parameter_name("radius"),
		get_parameter_name("time"),
		get_parameter_name("spacing")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_falling_copies(vec3 p, float radius, float time, float spacing) {
	// Create repeating space along y-axis with specified spacing
	vec3 repeated_p = p;
	repeated_p.y = mod(p.y + time * spacing, spacing) - spacing * 0.5;
	
	// Base sphere at repeated position
	float d = length(repeated_p) - radius;
	
	return d;
}
""" % id
