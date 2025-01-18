# prism.gd
class_name Prism
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "height", "type": TYPE_FLOAT, "default": 2.0, "min": 0.0001},
	{"name": "sides", "type": TYPE_FLOAT, "default": 6.0, "min": 3, "max": 16}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_prism(vec3 p, float radius, float height, float sides) {
	// Project point onto the XZ plane for the base polygon calculation
	vec2 q = vec2(length(p.xz), p.y);
	
	// Angle for one segment of the base polygon
	float segment = 3.14159265359 * 2.0 / sides;
	
	// Calculate the base polygon distance
	vec2 base = abs(q);
	float angle = atan(q.x, q.y);
	float slice = mod(angle, segment) - segment * 0.5;
	
	base = length(base) * vec2(cos(slice), abs(sin(slice)));
	base = base - vec2(radius, height * 0.5);
	
	// Final distance calculation
	float result = length(max(base, 0.0)) + min(max(base.x, base.y), 0.0);
	
return result;
}
	""" % id

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_prism(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("height"),
		get_parameter_name("sides")
	]
