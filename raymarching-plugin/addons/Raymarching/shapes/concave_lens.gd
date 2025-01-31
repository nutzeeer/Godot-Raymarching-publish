# lens.gd 
class_name Lens
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
	// Cylinder representing the base lens (radius in XZ, thickness in Y)
	vec2 cylinder_d = abs(vec2(length(p.xz), p.y)) - vec2(radius, thickness/2.0);
	float cylinder = min(max(cylinder_d.x, cylinder_d.y), 0.0) + length(max(cylinder_d, 0.0));
	
	// Calculate offset to ensure spheres touch cylinder's edge (Pythagoras)
	float offset = sqrt(max(sphere_radius * sphere_radius - radius * radius, 0.0));
	
	// Position spheres OUTSIDE the lens (corrected direction)
	vec3 top_center = vec3(0.0, thickness/2.0 + offset, 0.0); // Move UP
	vec3 bottom_center = vec3(0.0, -thickness/2.0 - offset, 0.0); // Move DOWN
	
	// Spheres to subtract from the cylinder
	float top_sphere = length(p - top_center) - sphere_radius;
	float bottom_sphere = length(p - bottom_center) - sphere_radius;
	
	// Combine cylinder with subtracted spheres
	return max(cylinder, -min(top_sphere, bottom_sphere));
}
""" % id
