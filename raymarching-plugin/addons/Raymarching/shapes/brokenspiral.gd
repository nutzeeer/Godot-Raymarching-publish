# broken_spiral.gd
class_name BrokenSpiral
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "twist_rate", "type": TYPE_FLOAT, "default": 3.0, "min": 0.1, "max": 20.0},
	{"name": "dimensions", "type": TYPE_VECTOR3, "default": Vector3.ONE, "min": 0.0001},
	{"name": "offset", "type": TYPE_FLOAT, "default": 0.5, "min": -10.0, "max": 10.0}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_broken_spiral(local_p, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("twist_rate"),
		get_parameter_name("dimensions"),
		get_parameter_name("offset")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_broken_spiral(vec3 p, float radius, float twist_rate, vec3 dimensions, float offset) {
	// This is an intentionally broken SDF that creates weird spiral-like artifacts
	float spiral = sin(atan(p.x, p.z) * twist_rate + p.y * offset);
	float dist = length(p) - radius;
	
	// Incorrect distance calculation that breaks SDF properties
	float result = dist * spiral * sin(length(p * dimensions));
	
	// This breaks the SDF property of returning true distance
	return result * (1.0 + sin(p.x * p.y * p.z));
}
""" % id
