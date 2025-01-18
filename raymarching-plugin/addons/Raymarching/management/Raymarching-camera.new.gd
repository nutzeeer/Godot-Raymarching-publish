@tool
extends Camera3D
#class_name RaymarchCamera

# Internal resources
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D
var _material: ShaderMaterial
var shader_generator: ShaderGenerator

# Raymarching parameters
@export_group("Raymarching Settings")
@export var max_steps: int = 500: set = set_max_steps
@export var max_distance: float = 1000.0: set = set_max_distance
@export_range(1e-4, 50, 1e-7) var surface_distance: float = 1: set = set_surface_distance
@export_range(1e-7, 0.1, 1e-7) var normal_precision: float = 0.0001: set = set_normal_precision

# Modifier handling
var for_loop_modifier: RaymarchModifiers = RaymarchModifiers.new()

# Raymarching-camera.new.gd
func _init() -> void:
	_setup_mesh()
	_setup_material()
	shader_generator = ShaderGenerator.new()
	

func _ready() -> void:

	for child in get_children():
		if child is ShapeManager:
			if not child.shapes_loaded.is_connected(update_shape_nodes):
				child.shapes_loaded.connect(update_shape_nodes)
	update_shape_nodes()
	$AnimationPlayer.play("new_animation_2")
	if Engine.is_editor_hint():
		pass

func _setup_mesh() -> void:
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)
	
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_add_vertex(Vector3(-1, -1, 0))
	_mesh.surface_add_vertex(Vector3(3, -1, 0))
	_mesh.surface_add_vertex(Vector3(-1, 3, 0))
	_mesh.surface_end()
	
	_mesh_instance.position = Vector3(0, 0, -1)

func _setup_material() -> void:
	_material = ShaderMaterial.new()
	_mesh_instance.material_override = _material
	

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			if Engine.is_editor_hint():
				update_shape_nodes()
		NOTIFICATION_EDITOR_PRE_SAVE:
			if Engine.is_editor_hint():
				update_shape_nodes()

func update_shape_nodes() -> void:
	# Clear existing shape resources
	shader_generator.shape_resources.clear()
	
	# Add and connect all shape managers
	for child in get_children():
		if child is ShapeManager:
			var id = shader_generator.add_shape_manager(child)
			# Connect signals
			# In RaymarchCamera.update_shape_nodes()
			print("Found ShapeManager:", child.name, " with ID:", id)
			if not child.shape_changed.is_connected(update_shape_nodes):
				child.shape_changed.connect(update_shape_nodes)
			if not child.modifier_changed.is_connected(update_shape_nodes):
				child.modifier_changed.connect(update_shape_nodes)
			if not child.properties_updated.is_connected(_on_properties_updated):
				child.properties_updated.connect(_on_properties_updated.bind(child))
	
	update_shader()

func update_shader() -> void:
	var shader = Shader.new()
	shader.code = shader_generator.generate_shader()
	
	# Debug output
	print("\n=== Generated Shader Code ===")
	print(shader.code)
	
	# Update material shader
	_material.shader = shader
	update_shader_parameters()

func update_shader_parameters() -> void:
	shader_generator.update_shader_parameters(_material)
	
	# Update raymarching parameters
	_material.set_shader_parameter("max_steps", max_steps)
	_material.set_shader_parameter("max_distance", max_distance)
	_material.set_shader_parameter("surface_distance", surface_distance)
	_material.set_shader_parameter("normal_precision", normal_precision)
	
	# Update for loop modifiers
	var modifier_params = for_loop_modifier.to_shader_params()
	for param_name in modifier_params:
		_material.set_shader_parameter(param_name, modifier_params[param_name])

	# Update raymarch parameters in shader generator
	shader_generator.raymarch_params.update_from_camera(self)
	
	# Update all parameters through shader generator
	shader_generator.update_shader_parameters(_material)
# Parameter setters
func set_max_steps(value: int) -> void:
	print("\n=== Setting max_steps ===")
	max_steps = value
	update_shader_parameters()

func set_max_distance(value: float) -> void:
	print("\n=== Setting max_distance ===")
	max_distance = value
	update_shader_parameters()

func set_surface_distance(value: float) -> void:
	print("\n=== Setting surface_distance ===")
	surface_distance = value
	update_shader_parameters()

func set_normal_precision(value: float) -> void:
	print("\n=== Setting normal_precision ===")
	normal_precision = value
	update_shader_parameters()

func _on_properties_updated(shape_manager: ShapeManager) -> void:
	#var id = shape_manager.get_instance_id()
	#if shader_generator.shape_resources.has(id):
		#shader_generator.shape_resources[id].update()
		update_shader_parameters()

# For Loop modifier methods
func set_for_loop_modifier(modifier_params: Dictionary) -> void:
	for_loop_modifier.ro_mul = modifier_params.get("ro_mul", Vector3.ONE)
	for_loop_modifier.rd_mul = modifier_params.get("rd_mul", Vector3.ONE)
	for_loop_modifier.pos_mul = modifier_params.get("pos_mul", Vector3.ONE)
	for_loop_modifier.surf_mul = modifier_params.get("surf_mul", 1.0)
	for_loop_modifier.max_mul = modifier_params.get("max_mul", 1.0)
	for_loop_modifier.ro_add = modifier_params.get("ro_add", Vector3.ZERO)
	for_loop_modifier.rd_add = modifier_params.get("rd_add", Vector3.ZERO)
	for_loop_modifier.pos_add = modifier_params.get("pos_add", Vector3.ZERO)
	for_loop_modifier.surf_add = modifier_params.get("surf_add", 0.0)
	for_loop_modifier.max_add = modifier_params.get("max_add", 0.0)
	
	if for_loop_modifier.validate():
		update_shader_parameters()



func _process(_delta: float) -> void:
	update_shader_parameters()
	#
	#print("Camera Transform Details:")
	#print("  Local Position: ", position)
	#print("  Local Rotation: ", rotation)
	#print("  Global Position: ", global_position)
	#print("  Transform-derived Rotation: ", transform.basis.get_euler())
	#print("  Global-transform Rotation: ", global_transform.basis.get_euler())
	#print("  Parent Rotation: ", get_parent().rotation if get_parent() else "no parent")
		##
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"max_steps", "max_distance", "surface_distance", "normal_precision":
			set(property, value)  # Call the corresponding setter method
			update_shader_parameters()  # Call existing function to trigger updates
			return true
	
	return false

func _exit_tree() -> void:
	if _material:
		_material.shader = null
	# Clear resources
	shader_generator.shape_resources.clear()
