@tool
extends Node3D
class_name ShapeManager



signal shape_changed()
signal properties_updated()
signal shapes_loaded  
# Add new signals
signal modifier_changed()
signal modifier_properties_updated()

var inverse_transform: Transform3D

var shape_classes: Dictionary = {}
var current_shape: ShapeBase = null
var shape_type: int = 0 : set = _set_shape_type
static var is_loaded: bool = false

# Modifier-related variables
var modifier_classes: Dictionary = {}  # Holds all loaded modifiers with capabilities
var active_modifiers: Dictionary = {}  # shape_id -> [active_modifiers]
var current_modifier: GeneralModifierBase = null  # Changed base class
var modifier_type: int = 0 : set = _set_modifier_type

func _init() -> void:
	print("ShapeManager _init called")
	top_level = true
	if Engine.is_editor_hint() or shape_classes.is_empty():
		print("Loading shapes in _init")
		_load_shape_classes()
		_load_modifier_classes()

func _ready() -> void:
	print("ShapeManager _ready called")
	
	# Load shapes if needed
	if shape_classes.is_empty():
		_load_shape_classes()
		
	#if Engine.is_editor_hint():
	shape_changed.connect(_set_shape_type)
	properties_updated.connect(_on_properties_updated)

func _enter_tree() -> void:
	print("ShapeManager _enter_tree called")
	#if Engine.is_editor_hint():
	print("Trying to load shapes in _enter_tree")
	_load_shape_classes()
		
# In shape_manager.gd

func _load_modifier_classes() -> void:
	if !modifier_classes.is_empty():
		return  # Already loaded
		
	print("=== Loading modifier classes start ===")
	
	var base_path = "res://addons/Raymarching/Modifiers"
	_scan_modifier_directory(base_path)
	
	print("Final modifier classes: ", modifier_classes.keys())

func _scan_modifier_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if !dir:
		push_error("Failed to open directory: " + path)
		return
	
	print("Scanning directory: " + path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			# Recursively scan subdirectories
			_scan_modifier_directory(full_path)
		elif file_name.ends_with(".gd"):
			# Skip base and template files
			if file_name == "general_modifier_base.gd" or file_name.ends_with("_template.gd"):
				file_name = dir.get_next()
				continue
				
			print("Found modifier file: ", file_name)
			var script = load(full_path)
			
			# Check if script extends GeneralModifierBase
			if script:
				var modifier_name = file_name.get_basename()
				var instance = script.new()
				
				# Create a descriptor of the modifier's capabilities
				var capabilities = {
					"script": script,
					"has_d_modifier": instance.has_d_modifier(),
					"has_p_modifier": instance.has_p_modifier(),
					"has_color_modifier": instance.has_color_modifier(),
					"has_forloop_modifier": instance.has_forloop_modifier(),  # Add this line
					"path": full_path
				}
				
				modifier_classes[modifier_name] = capabilities
				print("Successfully loaded modifier: ", modifier_name)
				print("  Capabilities: ", capabilities)
			else:
				push_warning("Skipped invalid modifier script: " + file_name)
				
		file_name = dir.get_next()
	
	dir.list_dir_end()


func _load_shape_classes() -> void:
	if !shape_classes.is_empty():
		return  # Already loaded
		
	print("=== _load_shape_classes start ===")
	
	var dir = DirAccess.open("res://addons/Raymarching/shapes/")
	if !dir:
		push_error("Failed to open shapes directory")
		return
	
	print("Directory opened successfully")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		print("Found file: ", file_name)
		if file_name.ends_with(".gd") and file_name != "shape_base.gd" and file_name != "shape_template.gd":
			var shape_name = file_name.get_basename()
			print("Processing shape: ", shape_name)
			var script = load("res://addons/Raymarching/shapes/" + file_name)
			if script:
				shape_classes[shape_name] = script
				print("Successfully loaded shape: ", shape_name)
			else:
				push_error("Failed to load script: " + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Final shape classes: ", shape_classes.keys())
	print("=== _load_shape_classes end ===")
	
	is_loaded = !shape_classes.is_empty()
	if is_loaded:
		shapes_loaded.emit()  # Emit the signal when shapes are loaded successfully

	if !shape_classes.is_empty():
		shapes_loaded.emit()
		# Restore current shape if shape_type is valid
		if shape_type >= 0 and shape_type < shape_classes.size():
			notify_property_list_changed()
			_update_inspector_properties()

func _set_shape_type(value: int) -> void:
	print("\n=== Setting shape type ===")
	print("Old value: ", shape_type)
	print("New value: ", value)
	
	if current_shape:
		current_shape = null
	
	shape_type = value

	#notify_property_list_changed()
	_update_inspector_properties()    # Create/update actual shape
	notify_property_list_changed()
	shape_changed.emit()
	properties_updated.emit()  # Add this line to trigger shader update

# In shape_manager.gd

func _set_modifier_type(value: int) -> void:
	print("\n=== Setting modifier type ===")
	print("Old value: ", modifier_type)
	print("New value: ", value)
	
	if current_modifier:
		current_modifier = null
	
	modifier_type = value
	
	if modifier_type > 0:  # 0 is "None"
		var modifier_keys = modifier_classes.keys()
		if modifier_type <= modifier_keys.size():
			var modifier_name = modifier_keys[modifier_type - 1]
			var selected_modifier = modifier_classes[modifier_name]
			if selected_modifier and selected_modifier.script:
				current_modifier = selected_modifier.script.new()
				current_modifier.set_node_3d(self)
	
	notify_property_list_changed()
	modifier_changed.emit()
	modifier_properties_updated.emit()
	properties_updated.emit()

func get_current_modifier() -> GeneralModifierBase:
	return current_modifier



func get_modifier_templates() -> Dictionary:
	if current_modifier:
		return {
			"d_template": current_modifier.get_d_modifier_template(),
			"p_template": current_modifier.get_p_modifier_template(),
			"color_template": current_modifier.get_color_modifier_template()
		}
	return {}

func get_modifier_parameters() -> Dictionary:
	if current_modifier:
		return current_modifier.get_all_parameters()
	return {}
	
func get_modifier_capabilities() -> Dictionary:
	if current_modifier:
		return {
			"has_d_modifier": current_modifier.has_d_modifier(),
			"has_p_modifier": current_modifier.has_p_modifier(),
			"has_color_modifier": current_modifier.has_color_modifier(),
			"has_forloop_modifier": current_modifier.has_forloop_modifier()  # Add this line
		}
	return {}

func _on_properties_updated() -> void:
	print("Properties updated")
	#notify_property_list_changed() #commented to avoid list regeneration.

# In shape_manager.gd

# Update get_current_shape_sdf to include modifier
func get_current_shape_sdf() -> String:
	if current_shape:
		var sdf = current_shape.get_sdf_function()
		if current_modifier:
			# Handle each modifier type
			var p_template = current_modifier.get_p_modifier_template()
			var d_template = current_modifier.get_d_modifier_template()
			
			# Add space modification before SDF calculation
			if p_template:
				sdf = sdf.replace(
					"vec3 local_p = ",
					"vec3 local_p = " + p_template
				)
			
			# Add SDF value modification after calculation
			if d_template:
				sdf = sdf.replace(
					"float result = ",
					"float result = " + d_template
				)
			
			return sdf
		return sdf
	return ""

func get_shader_data() -> Dictionary: 
	return {
		"shape": {
			"sdf": get_current_shape_sdf(),
			"parameters": get_current_shape_parameters_dict()
		},
		"modifier": {
			"pre_map_functions": current_modifier.get_pre_map_functions() if current_modifier else "",
			"d_template": current_modifier.get_d_modifier_template() if current_modifier else "",
			"p_template": current_modifier.get_p_modifier_template() if current_modifier else "",
			"color_template": current_modifier.get_color_modifier_template() if current_modifier else "",
			"forloop_template": current_modifier.get_forloop_modifier_template() if current_modifier else "",
			"utility_functions": current_modifier.get_utility_functions() if current_modifier else "",
			"custom_map_name": current_modifier.get_custom_map_name() if current_modifier else "",
			"custom_map_template": current_modifier.get_custom_map_template() if current_modifier else "",
			"parameters": get_modifier_parameters()
		}
	}
	
func _get_property_list() -> Array:
	print("\n=== _get_property_list ===")
	var properties = []
	
	# Existing shape type property
	var shape_keys = shape_classes.keys()
	if !shape_keys.is_empty():
		properties.append({
			"name": "shape_type",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(shape_keys)
		})
	
	# Add modifier property
	var modifier_keys = modifier_classes.keys()
	if !modifier_keys.is_empty():
		properties.append({
			"name": "modifier_type",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "None," + ",".join(modifier_keys)
		})
	
	# Add current shape parameters
	if current_shape:
		var all_params = current_shape.BASE_PARAMETERS + current_shape.get_shape_parameters()
		for param in all_params:
			properties.append(_create_parameter_dict(param))
	
	# Add current modifier parameters and capabilities
	if current_modifier:
		# Add capability indicators first for better organization
		properties.append({
			"name": "Modifier Capabilities",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "capabilities"
		})
		properties.append({
			"name": "has_D_result_modifier",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY,
			"value": current_modifier.has_d_modifier()
		})
		properties.append({
			"name": "has_local_p_modifier",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY,
			"value": current_modifier.has_p_modifier()
		})
		properties.append({
			"name": "has_color_surface_modifier",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY,
			"value": current_modifier.has_color_modifier()
		})
				# In _get_property_list(), add this with the other capability indicators
		properties.append({
			"name": "has_forloop_modifier",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY,
			"value": current_modifier.has_forloop_modifier() if current_modifier else false
		})
		
		# Add modifier parameters
		properties.append({
			"name": "Modifier Parameters",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "parameters"
		})
		var modifier_params = current_modifier.get_modifier_parameters()
		for param in modifier_params:
			properties.append(_create_parameter_dict(param))
	
	return properties
	
	
func _create_parameter_dict(param: Dictionary) -> Dictionary:
	var property_info = {
		"name": param.name,
		"type": param.type,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	}
	
	if "min" in param and "max" in param:
		property_info["hint"] = PROPERTY_HINT_RANGE
		if param.type == TYPE_VECTOR3 or param.type == TYPE_VECTOR2:
			property_info["hint_string"] = "%f,%f" % [param.min, param.max]
		else:
			property_info["hint_string"] = "%f,%f,0.001" % [param.min, param.max]
	
	return property_info
	
func _update_inspector_properties() -> void:
	print("\n=== _update_inspector_properties ===")
	print("Current shape type: ", shape_type)
	
	var shape_keys = shape_classes.keys()
	if shape_keys.is_empty():
		push_warning("No shape classes loaded")
		print("No shape classes loaded")
		return
		
	if shape_type >= 0 and shape_type < shape_keys.size():
		var shape_name = shape_keys[shape_type]
		print("Creating shape: ", shape_name)
		var selected_shape = shape_classes[shape_name]
		if selected_shape:
			current_shape = selected_shape.new()
			current_shape.set_node_3d(self)  # Connect the Node3D
			print("Shape created successfully")
			properties_updated.emit()

func _validate_parameter_value(param: Dictionary, value: Variant) -> bool:
	if typeof(value) != param.type:
		return false
	
	if "min" in param:
		match param.type:
			TYPE_FLOAT, TYPE_INT:
				if value < param.min:
					return false
			TYPE_VECTOR2, TYPE_VECTOR3:
				for component in value:
					if component < param.min:
						return false
	
	if "max" in param:
		match param.type:
			TYPE_FLOAT, TYPE_INT:
				if value > param.max:
					return false
			TYPE_VECTOR2, TYPE_VECTOR3:
				for component in value:
					if component > param.max:
						return false
	
	return true

func get_current_shape() -> ShapeBase:
	return current_shape

func get_current_shape_parameters() -> Array:
	if current_shape:
		return current_shape.BASE_PARAMETERS + current_shape.get_shape_parameters()
	return []

func _process(_delta: float) -> void:
	# Update transform and inverse transform
	var new_inverse_transform = transform.affine_inverse()
	# Only emit if transform actually changed
	if new_inverse_transform != inverse_transform:
		inverse_transform = new_inverse_transform
		properties_updated.emit()  # New signal for just parameter updates


func get_current_shape_parameters_dict() -> Dictionary:
	var params = {}
	if current_shape:
		for key in current_shape.property_values:
			params[key] = current_shape.get(key)
		# Add transform parameters
		params["position"] = position
		params["rotation"] = rotation
		params["scale"] = scale
		#Adding inverse transforms to be precalculated
		params["inverse_transform"] = inverse_transform

	return params


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		print("Editor pre-save notification")

func _get(property: StringName) -> Variant:
	# Handle transforms at ShapeManager level
	match property:
		"position":
			return position
		"rotation":
			return rotation
		"scale":
			return scale
		"modifier_type":
			return modifier_type
		"has_D_result_modifier":
			return current_modifier.has_d_modifier() if current_modifier else false
		"has_local_p_modifier":
			return current_modifier.has_p_modifier() if current_modifier else false
		"has_color_surface_modifier":
			return current_modifier.has_color_modifier() if current_modifier else false
	   
	
	# Handle shape-specific properties
	if current_shape and current_shape.property_values.has(property):
		return current_shape._get(property)

	# Handle modifier-specific properties
	if current_modifier and current_modifier.property_values.has(property):
		return current_modifier.property_values[property]
	
	return null

# In shape_manager.gd

func _set(property: StringName, value: Variant) -> bool:
	# Handle transforms at ShapeManager level
	match property:
		"position":
			position = value
			properties_updated.emit()
			return true
		"rotation":
			rotation = value
			properties_updated.emit()
			return true
		"scale":
			scale = value
			properties_updated.emit()
			return true
		"modifier_type":
			_set_modifier_type(value)
			properties_updated.emit()
			return true
	
	# Handle shape parameters
	if current_shape and current_shape.property_values.has(property):
		current_shape._set(property, value)
		properties_updated.emit()
		return true
	
	# Handle modifier parameters
	if current_modifier and current_modifier.property_values.has(property):
		current_modifier.property_values[property] = value
		properties_updated.emit()
		modifier_properties_updated.emit()
		return true
	
	return false

# Add a debug method to verify parameter values
func debug_modifier_params() -> void:
	if current_modifier:
		print("\nCurrent modifier parameters:")
		for param_name in current_modifier.property_values:
			print("%s: %s" % [param_name, str(current_modifier.property_values[param_name])])
	
func _exit_tree() -> void:
	if current_shape:
		current_shape = null
	
	# Disconnect any connected signals
	if shape_changed.is_connected(_set_shape_type):
		shape_changed.disconnect(_set_shape_type)
	if properties_updated.is_connected(_on_properties_updated):
		properties_updated.disconnect(_on_properties_updated)
	if modifier_changed.is_connected(_set_modifier_type):
		modifier_changed.disconnect(_set_modifier_type)
