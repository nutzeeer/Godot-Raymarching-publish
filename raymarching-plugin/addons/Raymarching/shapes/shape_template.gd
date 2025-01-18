# shape_template.gd
class_name ShapeTemplate
extends ShapeBase

# Define all parameters for this shape as a constant array of dictionaries
# Each parameter definition should include:
# - name: The parameter's name (String)
# - type: GDScript type constant (e.g., TYPE_FLOAT, TYPE_VECTOR3)
# - default: Default value for the parameter
# - min: (Optional) Minimum allowed value
# - max: (Optional) Maximum allowed value
const SHAPE_PARAMETERS = [
	# Example float parameter with range
	{"name": "radius", "type": TYPE_FLOAT, "default": 1.0, "min": 0.0001},
	# Example integer parameter with range
	{"name": "sides", "type": TYPE_INT, "default": 6, "min": 3, "max": 16},
	# Example vector parameter with minimum values
	{"name": "dimensions", "type": TYPE_VECTOR3, "default": Vector3.ONE, "min": 0.0001},
	# Example unrestricted parameter
	{"name": "offset", "type": TYPE_FLOAT, "default": 0.0}
]

# Override get_shape_parameters to return this shape's specific parameters
func get_shape_parameters() -> Array:
	return SHAPE_PARAMETERS

# Override get_sdf_function to return the GLSL code for this shape's SDF
# The function should:
# - Have a unique name using sdf_shape{id}_template format
# - Take vec3 p as its first parameter for the point to evaluate
# - Take additional parameters matching the parameters defined above
# - Return a float representing the signed distance
# - Include a %s in the function name which will be replaced with the shape's unique id
func get_sdf_function() -> String:
	var id = get_shape_id()
	return """
	float sdf_shape%s_template(vec3 p, float radius, float sides, vec3 dimensions, float offset) { // ") {" is used for string analysis and must be kept as is. appending parameters. 
		// SDF implementation here
		float result = calculation
return result;
	} 
	""" % id

# Override get_sdf_call to return the function call for this shape's SDF
# The function call should:
# - Use the same unique function name as defined in get_sdf_function
# - Use 'local_p' as the position parameter
# - Use get_parameter_name() for all other parameters to ensure unique parameter names
# - Match parameter order with the SDF function definition
func get_sdf_call() -> String:
	var id = get_shape_id()
	return "sdf_shape%s_template(local_p, %s, %s, %s, %s)" % [
		id,
		get_parameter_name("radius"),
		get_parameter_name("sides"),
		get_parameter_name("dimensions"),
		get_parameter_name("offset")
	]
