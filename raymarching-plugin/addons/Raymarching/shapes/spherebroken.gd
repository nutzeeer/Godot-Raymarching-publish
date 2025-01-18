# broken_sphere.gd
class_name BrokenSphere
extends ShapeBase

const SHAPE_PARAMETERS = [
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	{"name": "distortion", "type": TYPE_FLOAT, "default": 0.5, "min": 0.0, "max": 2.0},
	{"name": "frequency", "type": TYPE_FLOAT, "default": 3.0, "min": 0.1}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_broken_sphere(local_p, %s, %s, %s)" % [
		id, 
		get_parameter_name("radius"),
		get_parameter_name("distortion"),
		get_parameter_name("frequency")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_broken_sphere(vec3 p, float radius, float distortion, float frequency) {
	// Core calculation with intentional flaws
	float base = length(p) - radius;
	
	// These operations break the signed distance field properties
	vec3 broken_p = p * (1.0 + sin(p.x * frequency) * distortion);
	float broken_dist = length(broken_p) - radius;
	
	// Incorrect distance mixing that violates SDF properties
	float result = base + (broken_dist - base) * (0.5 + 0.5 * sin(length(p)));
	
	// Non-linear scaling that breaks distance field properties
	result *= 1.0 + 0.3 * sin(dot(p, p));
	
	return result;
}
""" % id
