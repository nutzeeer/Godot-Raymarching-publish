# lens.gd 
class_name Lens2
extends ShapeBase

const SHAPE_PARAMETERS = [
	{
		"name": "radius",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0001,
		"description": "Outer radius of the lens"
	},
	{
		"name": "thickness",
		"type": TYPE_FLOAT,
		"default": 0.2,
		"min": 0.0001,
		"description": "Total thickness of the lens at its edges"
	},
	{
		"name": "sphere_radius", 
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.0001,
		"description": "Radius of the spherical cutouts that create the concave surfaces"
	}
]

func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_lens(local_p, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("thickness"),
		get_parameter_name("sphere_radius")
	]

func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
float sdf_shape%s_lens(vec3 p, float radius, float thickness, float sphere_radius) {
	// Create cylinder
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(radius, thickness/2.0);
	float cylinder = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
	
	// Create spherical cutouts
	float top_sphere = length(p - vec3(0.0, thickness/2.0, 0.0)) - sphere_radius;
	float bottom_sphere = length(p - vec3(0.0, -thickness/2.0, 0.0)) - sphere_radius;
	
	// Combine using subtraction
	float result = max(cylinder, -min(top_sphere, bottom_sphere));
	return result;
}
""" % id
