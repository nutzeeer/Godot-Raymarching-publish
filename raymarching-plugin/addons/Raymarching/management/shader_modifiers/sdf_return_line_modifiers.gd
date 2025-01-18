# sdf_return_line_modifiers.gd

class_name SDFReturnLineModifiers

# Each entry contains:
# - name: Display name for the UI
# - template: GLSL code template with {parameter} placeholders
# - parameters: Dictionary of parameter names and their default values
# - description: Optional explanation of the modifier
static var modifiers = [
	{
		"name": "Standard",
		"template": "return distance;",
		"parameters": {},
		"description": "Standard SDF return"
	},
	{
		"name": "Add Parent",
		"template": "return distance + {parent_shape};",
		"parameters": {"parent_shape": "0.0"},
		"description": "Adds parent shape's SDF value. Modify as needed."
	},
	 {
		"name": "Smooth Blend Parent",
		"template": "return mix(distance, {parent_shape}, {blend_factor});",
		"parameters": {
			"parent_shape": "0.0",
			"blend_factor": "0.5"
		},
		"description": "Smoothly blends with parent shape"
	},
	{
		"name": "Offset",
		"template": "return distance - {offset};",
		"parameters": {"offset": "1.0"},
		"description": "Expands or contracts the shape"
	},
	{
		"name": "Soft Edge",
		"template": "return distance - smoothstep(0.0, {softness}, distance);",
		"parameters": {"softness": "0.5"},
		"description": "Creates soft edges"
	},
	{
		"name": "Twist",
		"template": "float angle = position.y * {twist_amount};\nfloat c = cos(angle);\nfloat s = sin(angle);\nvec3 twisted = vec3(c * position.x - s * position.z, position.y, s * position.x + c * position.z);\nreturn distance * length(twisted) / length(position);",
		"parameters": {"twist_amount": "1.0"},
		"description": "Applies twist deformation around Y axis"
	},
	{
		"name": "Bend",
		"template": "float bend = {bend_amount} * position.x;\nfloat c = cos(bend);\nfloat s = sin(bend);\nvec3 bent = vec3(position.x, c * position.y - s * position.z, s * position.y + c * position.z);\nreturn distance * length(bent) / length(position);",
		"parameters": {"bend_amount": "1.0"},
		"description": "Applies bend deformation"
	},
	{
		"name": "Domain Repetition",
		"template": "vec3 rep = mod(position + 0.5 * {spacing}, {spacing}) - 0.5 * {spacing};\nreturn distance * length(rep) / length(position);",
		"parameters": {"spacing": "2.0"},
		"description": "Repeats the shape in 3D space"
	},
	{
		"name": "Ripple",
		"template": "return distance + sin(position.x * {frequency}) * {amplitude};",
		"parameters": {
			"frequency": "1.0",
			"amplitude": "0.5"
		},
		"description": "Adds sinusoidal surface distortion"
	},
	{
		"name": "Noise Distortion",
		"template": "return distance + noise(position * {noise_scale}) * {noise_strength};",
		"parameters": {
			"noise_scale": "1.0",
			"noise_strength": "0.5"
		},
		"description": "Adds noise-based distortion"
	},
	{
		"name": "Shell",
		"template": "return abs(distance) - {thickness};",
		"parameters": {"thickness": "0.1"},
		"description": "Creates a hollow shell"
	},
	 {
		"name": "Surface Wave",
		"template": "return distance + sin(position.{axis} * {frequency} + time * {speed}) * {amplitude};",
		"parameters": {
			"axis": "x",
			"frequency": "5.0",
			"speed": "1.0",
			"amplitude": "0.2"
		},
		"description": "Adds animated wave distortion along specified axis"
	},
	{
		"name": "3D Noise",
		"template": "vec3 noisePos = position * {scale};\nfloat n = noise3D(noisePos + vec3(time * {time_scale}));\nreturn distance + n * {strength};",
		"parameters": {
			"scale": "2.0",
			"time_scale": "0.5",
			"strength": "0.3"
		},
		"description": "3D noise-based surface distortion"
	},
	{
		"name": "Smooth Blend Parent",
		"template": "return mix(distance, {parent_shape}, {blend_factor});",
		"parameters": {
			"parent_shape": "0.0",
			"blend_factor": "0.5"
		},
		"description": "Smoothly blends with parent shape"
	},
	{
		"name": "Custom",
		"template": "{custom_expression}",
		"parameters": {"custom_expression": "return distance;"},
		"description": "Custom return line expression"
	}
]

static func get_modifier(index: int) -> Dictionary:
	return modifiers[index] if index < modifiers.size() else modifiers[0]

static func get_modifier_names() -> Array:
	return modifiers.map(func(mod): return mod.name)

static func apply_parameters(template: String, params: Dictionary) -> String:
	var result = template
	for param in params:
		result = result.replace("{" + param + "}", str(params[param]))
	return result
