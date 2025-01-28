class_name ShaderGenerator
extends Resource

var next_shape_id: int = 0  # Sequential ID counter

class RaymarchParameters:
	extends RefCounted
	
	var max_steps: int = 100
	var max_distance: float = 1000.0
	var surface_distance: float = 0.001
	var normal_precision: float = 0.001
	
	func update_from_camera(camera: Camera3D) -> void:

		
		max_steps = camera.max_steps
		max_distance = camera.max_distance
		surface_distance = camera.surface_distance
		normal_precision = camera.normal_precision
	


class ShapeParameter:
	var name: String
	var type: int
	var value: Variant
	
	func _init(p_name: String, p_type: int, p_value: Variant):
		name = p_name
		type = p_type
		value = p_value
	
	# Convert GDScript types to GLSL uniform declarations
	func get_uniform_declaration() -> String:
		match type:
			TYPE_BOOL:
				return "uniform bool "  # Add this case	
			TYPE_FLOAT:
				return "uniform float "
			TYPE_INT:
				return "uniform int "
			TYPE_VECTOR3:
				return "uniform vec3 "
			TYPE_VECTOR2:
				return "uniform vec2 "
			TYPE_BASIS:
				return "uniform mat3 "
			TYPE_TRANSFORM3D:
				return "uniform mat4 "
			_:
				push_warning("Unsupported parameter type: " + str(type))
				return "uniform float "  # fallback


class ShapeResource:
	extends RefCounted
	
	var manager: ShapeManager
	var parameters: Dictionary
	var sdf_code: String
	var transform: Transform3D
	var modifier_parameters: Dictionary  # Add this
	var modifier_templates: Dictionary  # Store all modifier templates
	var sequential_id: int  # Declare sequential_id here

	
	signal resource_updated  # Add this line at the top of the class

	
	func _init(p_manager: ShapeManager, p_sequential_id: int) -> void:
		manager = p_manager
		sequential_id = p_sequential_id  # Add this line
		parameters = {}
		update()
	
	func update() -> void:
		print("ShapeResource update called - signal received")
		if manager:
			print("\n=== ShapeResource Update ===")
			var shape = manager.get_current_shape()
			print("Manager:", manager.name)
			transform = manager.global_transform
			print("Transform:", transform)
			if shape:
				print("Current shape:", shape)
				print("Shape class:", shape.get_class())
				shape.sequential_id = sequential_id  # Pass sequential_id to the shape
				parameters = shape.get_all_parameters()
				print("Parameters:", parameters)
				sdf_code = shape.get_sdf_function()
				print("SDF code:", sdf_code)
				
			# Update modifier data
			var shader_data = manager.get_shader_data()
			if manager.current_modifier:
				modifier_templates = {
					"pre_map_functions": shader_data.modifier.pre_map_functions,
					"d_template": shader_data.modifier.d_template,
					"p_template": shader_data.modifier.p_template,
					"color_template": shader_data.modifier.color_template,
					"forloop_template": shader_data.modifier.forloop_template,
					"utility_functions": shader_data.modifier.utility_functions,
					"custom_map_name": shader_data.modifier.custom_map_name,
					"custom_map_template": shader_data.modifier.custom_map_template
				}
				modifier_parameters = shader_data.modifier.parameters
				print("Modifier parameters updated:", modifier_parameters)
				print("Modifier templates updated:", modifier_templates)
			else:
				modifier_parameters.clear()
				modifier_templates = {
					"pre_map_functions": "",
					"d_template": "",
					"p_template": "",
					"color_template": "",
					"forloop_template": "",
					"utility_functions": "",
					"custom_map_name": "",
					"custom_map_template": ""
				}
	
	func _process(_delta: float) -> void:
		
		if manager:
			var shape = manager.get_current_shape()
			if shape:
				# Update parameters from live values
				for param_name in parameters:
					parameters[param_name] = shape.get(param_name)
			if manager.current_modifier:
				for param_name in modifier_parameters:
					modifier_parameters[param_name] = manager.current_modifier.get(param_name)




var shape_resources: Dictionary = {}  # node_id -> ShapeResource
var raymarch_params: RaymarchParameters

func _init() -> void:
	shape_resources = {}
	raymarch_params = RaymarchParameters.new()

func add_shape_manager(manager: ShapeManager) -> int:
	var resource = ShapeResource.new(manager, next_shape_id)  # Modify this line
	shape_resources[next_shape_id] = resource  # Use next_shape_id as the key
	next_shape_id += 1  # Increment the counter
	# Debug print to verify connection
	print("Connecting shape_changed signal from manager to resource.update")
	# Add connection for shape changes
	if !manager.shape_changed.is_connected(resource.update):
		manager.shape_changed.connect(resource.update)
		print("Shape change signal connected successfully")
	if !manager.modifier_changed.is_connected(resource.update):
		manager.modifier_changed.connect(resource.update)
		print("modifier changed signal connected successfully")

	return resource.sequential_id  # Return the sequential ID

	
	

func generate_shader() -> String:
	var shader_code = "shader_type spatial;\n"
	shader_code += "render_mode unshaded;\n\n"
	
	#generate_uniform_declaration()

	# Add uniform declarations
	shader_code += generate_uniforms()
	
	
	# Add modifier includes and structures
	#shader_code = integrate_modifiers(shader_code)
	shader_code += """
	// TODO: Implement ray modifiers
	// Will include:
	// - For loop modifiers for ray direction and position
	// - Return line modifiers for SDF calculations
	// See for_loop_modifiers.gd and sdf_return_line_modifiers.gd
	
	
struct DebugInfo {
	float t;
	float d;
	float steps;
	vec3 normal;
	vec3 pos;
	int shape_id;
};

vec4 encode_debug_info(DebugInfo debug) {
	// Pack multiple values into RGBA
	return vec4(debug.t, debug.d, float(debug.steps), float(debug.shape_id));
}
	"""
	


	shader_code += generate_pre_map_functions()

	# Add SDF functions from all shapes
	shader_code += generate_sdf_functions()

		
	# Add map function
	shader_code += generate_all_maps()
	
		# Add utility functions
	shader_code += generate_utility_functions()

	# Add main shader code
	shader_code += generate_main_code()
	

	
	return shader_code

func generate_uniforms() -> String:
	var code = """
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform int MAX_STEPS;
uniform float MAX_DISTANCE;
uniform float SURFACE_DISTANCE;
uniform float NORMAL_PRECISION;
uniform float PHYSICS_TIME;  // Add this

"""
	
	for id in shape_resources:
		code += generate_shape_uniforms(id)
		code += generate_modifier_uniforms(id)
	return code


func generate_shape_uniforms(id: int) -> String:
	var resource = shape_resources[id]
	var code = "\n// Shape %d uniforms\n" % resource.sequential_id  # Use sequential_id
	code += generate_uniform_declaration(resource.sequential_id, "transform", ShapeParameter.new("transform", TYPE_TRANSFORM3D, resource.transform))
	
	# Add parameters
	var parameters = resource.parameters.duplicate()
	for param_name in parameters:
		var param_value = parameters[param_name]
		var param = ShapeParameter.new(param_name, typeof(param_value), param_value)
		code += generate_uniform_declaration(resource.sequential_id, param_name, param)
	
	return code

func generate_modifier_uniforms(id: int) -> String:
	var resource = shape_resources[id]
	var code = "\n// Shape %d modifier uniforms\n" % resource.sequential_id  # Use sequential_id
	
	for param_name in resource.modifier_parameters:
		var param_value = resource.modifier_parameters[param_name]
		var param = ShapeParameter.new(param_name, typeof(param_value), param_value)
		code += generate_uniform_declaration(resource.sequential_id, "mod_" + param_name, param)
	
	return code

func generate_map_function(effect_map_name: String, shape_resources: Array, effect_map_template: String = "") -> String:
	var template = effect_map_template
	if template.is_empty():
		template = """
float ${MAP_NAME}(vec3 p) {
	float final_distance = MAX_DISTANCE;
	${SHAPES_CODE}
	return final_distance;
}"""

	var shape_calculations = ""
	for shape in shape_resources:
		if shape.manager.get_current_shape():
			shape_calculations += "    {\n"
			
			# Apply space (p) modifications first if any
			if shape.modifier_templates.p_template:
				shape_calculations += "        // Space modification\n"
				var processed_p_template = shape.modifier_templates.p_template
				for param_name in shape.modifier_parameters:
					var uniform_name = "shape%d_mod_%s" % [shape.sequential_id, param_name]  # Use sequential_id
					processed_p_template = processed_p_template.replace("{%s}" % param_name, uniform_name)
				shape_calculations +=  processed_p_template + "\n        vec3 modified_p = result; \n" 
				shape_calculations += "        vec3 local_p = (inverse(shape%d_transform) * vec4(modified_p, 1.0)).xyz;\n" % shape.sequential_id  # Use sequential_id
			else:
				shape_calculations += "        vec3 local_p = (inverse(shape%d_transform) * vec4(p, 1.0)).xyz;\n" % shape.sequential_id  # Use sequential_id
			
			# Calculate base SDF
			shape_calculations += "        float d = " + shape.manager.get_current_shape().get_sdf_call() + ";\n"
			
			# Apply SDF (d) modifications if any
			if shape.modifier_templates.d_template:
				shape_calculations += "        // SDF modification\n"
				var processed_d_template = shape.modifier_templates.d_template
				for param_name in shape.modifier_parameters:
					var uniform_name = "shape%d_mod_%s" % [shape.sequential_id, param_name]  # Use sequential_id
					processed_d_template = processed_d_template.replace("{%s}" % param_name, uniform_name)
				shape_calculations += "        " + processed_d_template + "\n"
			# After SDF and modifier calculations
			if effect_map_name == "map_id":
				#Special case for shape identification
				shape_calculations += "        if (d < current_accuracy) { current_id = %d; }\n" % shape.sequential_id  # Use sequential_id
			else:
				# Store result for standard map evaluation
				shape_calculations += "        final_distance = min(final_distance, d);\n"

			shape_calculations += "    }\n"
	
	return template.replace("${MAP_NAME}", effect_map_name).replace("${SHAPES_CODE}", shape_calculations)
	
func generate_uniform_declaration(id: int, name: String, param: ShapeParameter) -> String:
	return param.get_uniform_declaration() + "shape" + str(id) + "_" + name + ";\n"

func integrate_modifiers(code: String) -> String:
	return """
#include "for_loop_modifiers.gdshaderinc"

${code}

vec3 apply_modifiers(vec3 p, RayModifiers mods) {
	return apply_modifier_vec3(p, mods.pos_add, mods.pos_mul);
}
""".replace("${code}", code)

func generate_pre_map_functions() -> String:
	var code = ""
	var pre_map_functions = {}  # Dictionary to store unique pre_map_functions
	
	for id in shape_resources:
		var resource = shape_resources[id]
		if resource.modifier_templates.get("pre_map_functions"):
			# Process parameters
			var processed_template = resource.modifier_templates.pre_map_functions
			for param_name in resource.modifier_parameters:
				var uniform_name = "shape%s_mod_%s" % [id, param_name]
				processed_template = processed_template.replace("{%s}" % param_name, uniform_name)
			pre_map_functions[processed_template] = true
	
	# Add each unique pre_map_function once
	for pre_func in pre_map_functions:
		code += pre_func + "\n"
	
	return code

func generate_utility_functions() -> String:
	var code = """
vec3 getNormal(vec3 p) {
	// Use smaller epsilon based on distance from point
	float eps = NORMAL_PRECISION * length(p);
	vec2 e = vec2(eps, 0.0);
	
	// Calculate normal with weighted central differences
	vec3 n = vec3(
		map(p + e.xyy) - map(p - e.xyy),
		map(p + e.yxy) - map(p - e.yxy),
		map(p + e.yyx) - map(p - e.yyx)
	);
	return normalize(n);
}

float get_soft_shadow(vec3 ro, vec3 rd, float min_t, float max_t, float k) {
	float result = 1.0;
	float ph = 1e10;
	float t = min_t;
	
	for(int i = 0; i < 256 && t < max_t; i++) {
		float h = map(ro + rd * t);
		if(h < 0.00001) return 0.0;
		
		// Use simpler calculation for far distances
		if(t > 10.0) {
			result = min(result, k * h / t);
		} else {
			float y = h*h/(2.0*ph);
			float d = sqrt(h*h-y*y);
			result = min(result, k*d/max(0.0,t-y));
		}
		ph = h;
		t += h;
	}
	return result;
}
"""
 # Collect all unique utility functions first
	var utility_functions = {}  # Dictionary to store unique utility functions
	for resource in shape_resources.values():
		if resource.modifier_templates.get("utility_functions"):
			utility_functions[resource.modifier_templates.utility_functions] = true
	
	# Add utility functions only once
	for util_func in utility_functions:
		code += util_func + "\n"
  
	return code



func generate_sdf_functions() -> String:
	var code = ""
	for resource in shape_resources.values():
		if resource.sdf_code:
			code += resource.sdf_code + "\n"
	return code
	
func generate_all_maps() -> String:
	var shader_code = ""
	
	# Create groups for shapes by their special effects
	var map_groups_by_effect: Dictionary = {}  # effect_map_name -> Array[ShapeResource]
	var shapes_without_effects: Array = []     # Shapes without special effects
	
	# First pass: organize shapes by their special effects
	for id in shape_resources:
		var shape = shape_resources[id]
		if shape.modifier_templates.get("custom_map_name"):
			var effect_map_name = shape.modifier_templates.custom_map_name
			if !map_groups_by_effect.has(effect_map_name):
				map_groups_by_effect[effect_map_name] = []
			map_groups_by_effect[effect_map_name].append(shape)
		else:
			shapes_without_effects.append(shape)
	
	# Generate special effect maps first
	for effect_map_name in map_groups_by_effect:
		var shapes_with_effect = map_groups_by_effect[effect_map_name]
		if shapes_with_effect.size() > 0:
			# Get the map template from the first shape with this effect
			var effect_map_template = shapes_with_effect[0].modifier_templates.get("custom_map_template", "")
			shader_code += generate_map_function(effect_map_name, shapes_with_effect, effect_map_template)
	
	# Generate the standard map with all shapes
	shader_code += generate_map_function("map", shape_resources.values())
	
	# ID map template that returns shape ID when SDF indicates a surface hit
	var id_template = """
	int ${MAP_NAME}(vec3 p, float current_accuracy) {
		float final_distance = MAX_DISTANCE;
		int current_id = 0;
		${SHAPES_CODE}
		return current_id;
	}"""

	shader_code += generate_map_function("map_id", shape_resources.values(), id_template)
		
	
	return shader_code

func get_shape_function_name(resource: ShapeResource) -> String:
	var shape = resource.manager.get_current_shape()
	return "sd" + shape.get_class() if shape else "sdSphere"

func get_shape_parameters_string(resource: ShapeResource) -> String:
	var params = []
	for param_name in resource.parameters:
		if param_name not in ["position", "rotation", "scale"]:
			params.append(param_name)
	return ", " + ", ".join(params) if params else ""

func generate_main_code() -> String:
	var code = """
void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec3 weird_uv = vec3(SCREEN_UV * 2.0 - 1.0, 0.0);
	vec4 camera = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(weird_uv, 1.0);
	
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float scene_depth = length(pixel_position);
	
	
	vec3 ray_origin = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 ray_dir = normalize(camera.xyz);
	vec3 current_rd = ray_dir;
	
	/*
	// Apply modifiers
	ray_origin = apply_modifiers(ray_origin, RayModifiers);
	ray_dir = apply_modifiers(ray_dir, RayModifiers);
	*/
	
	float t = 0.0;
	float current_accuracy = 0.0;  // Start at 0 like original
	float pixel_scale = 1.0 / min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y);
	bool hit = false;
	vec3 hit_normal;
	vec3 hit_pos;
	int i = 0;

	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 pos = ray_origin + current_rd * t;
		float d = map(pos);

		// Apply for-loop modifications based on shape ID
		int current_shape_id = map_id(pos, current_accuracy);
		
		//if (length(pos) < scene_depth) { //Z buffer integration with mesh scenery
			//discard;
		//	break;
		//}
		
		"""
	# Process for_loop templates by shape
	for id in shape_resources:
		var resource = shape_resources[id]
		if resource.modifier_templates.forloop_template:
			# Process parameters first
			var processed_template = resource.modifier_templates.forloop_template
			for param_name in resource.modifier_parameters:
				var uniform_name = "shape%s_mod_%s" % [id, param_name]
				processed_template = processed_template.replace("{%s}" % param_name, uniform_name)
			
			# Add shape-specific for-loop modification
			code += """
			if (current_shape_id == %d) {
				%s
			}
			""" % [id, processed_template]

	# Continue with existing code
	code += """
		
		if (d < current_accuracy) {
			hit = true;
			hit_pos = pos;
			hit_normal = getNormal(pos);
			break;
		}
		
		t += d;
		current_accuracy = t * SURFACE_DISTANCE * pixel_scale;  // Update at end like original
		if (t > MAX_DISTANCE) break;
	}
	
	vec3 camera_rotation;
camera_rotation.x = atan(INV_VIEW_MATRIX[1][2], INV_VIEW_MATRIX[2][2]);
camera_rotation.y = -asin(INV_VIEW_MATRIX[0][2]);
camera_rotation.z = atan(INV_VIEW_MATRIX[0][1], INV_VIEW_MATRIX[0][0]);
	//hit = true;
	
	
	DebugInfo debug;
debug.t = 0.0;
//debug.d = 0.0;
//debug.steps = float(i);
debug.normal = vec3(0.0);
debug.pos = vec3(0.0);
debug.shape_id = 0;
	
	
	
	
	if (hit) {
		
		int shape_id = map_id(hit_pos, current_accuracy);

			debug.t = t;
	//debug.d = d;
	debug.normal = hit_normal;
	debug.pos = hit_pos;
	debug.shape_id = shape_id;

		ALPHA = 1.0;
		//
//ALBEDO = mix(ALBEDO,vec3(0.0),0.5);
		//ALBEDO = hit_normal * 0.5 + 0.5;
		//ALBEDO = hit_normal * 0.5 + 0.5 * t;
"""
	
	# In generate_main_code()
	# Apply color/surface modifications
# In generate_main_code()
# Apply color/surface modifications
	for id in shape_resources:
		var resource = shape_resources[id]
		if resource.modifier_templates.color_template:
			# Process parameters first
			var processed_color = resource.modifier_templates.color_template
			for param_name in resource.modifier_parameters:
				var uniform_name = "shape%s_mod_%s" % [id, param_name]
				processed_color = processed_color.replace("{%s}" % param_name, uniform_name)
			
			# Then insert the processed template into the if statement
			code += """        // Surface modification for shape %s
			if (shape_id == %s) {
				
				%s
				
			} 
	""" % [id, id, processed_color]
	code += """
		
		
		// Calculate lighting
		vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
		float diffuse = max(0.0, dot(hit_normal, light_dir));
		float shadow = get_soft_shadow(hit_pos, light_dir, 0.0001, 1000.0, 32.0);
		//ALBEDO *= current_accuracy*10.0;
		ALBEDO *= (diffuse * shadow + 0.1);
		//ALBEDO = INV_VIEW_MATRIX[0].xyz; //Directional color
	} else {
		discard;
	}
//ALBEDO = (camera_rotation / (2.0 * PI)) + 0.5;

}
"""
	return code
	
	
func wrap_forloop_template(template: String, map_name: String, shape_id: int) -> String:
	if template == "" or map_name == "":
		return ""
		
	return """
	// Check if we're near the surface of this shape
	float effect_distance = %s(pos);
	if (effect_distance < current_accuracy) {
		// Check if this is the correct shape
		int current_shape_id = map_id(pos, current_accuracy);
		if (current_shape_id == %d) {
			%s
		}
	}
	""" % [map_name, shape_id, template]

# Update update_shader_parameters
func update_shader_parameters(material: ShaderMaterial) -> void:
	# Raymarching parameters
	material.set_shader_parameter("MAX_STEPS", raymarch_params.max_steps)
	material.set_shader_parameter("MAX_DISTANCE", raymarch_params.max_distance)
	material.set_shader_parameter("SURFACE_DISTANCE", raymarch_params.surface_distance)
	material.set_shader_parameter("NORMAL_PRECISION", raymarch_params.normal_precision)

	# Update shape-specific parameters
	for id in shape_resources:
		var resource = shape_resources[id]
		var prefix = "shape%s_" % resource.sequential_id
		
		# Update transform
		material.set_shader_parameter(
			prefix + "transform",
			resource.manager.global_transform
		)
		
		# Update shape parameters
		var shape = resource.manager.get_current_shape()
		if shape:
			for param_name in resource.parameters:
				material.set_shader_parameter(
					prefix + param_name,
					shape.get(param_name)
				)
			
		# Update modifier parameters
		var modifier = resource.manager.current_modifier
		if modifier:
			for param_name in resource.modifier_parameters:
				material.set_shader_parameter(
					prefix + "mod_" + param_name,
					modifier.get(param_name)
				)
