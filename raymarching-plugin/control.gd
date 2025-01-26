extends Control

@onready var camera: Camera3D = $"Node3D/RaymarchCamera"  # Adjust path as needed
@onready var info_label: Label = $InfoLabel

func _ready():
	info_label = Label.new()
	add_child(info_label)
	info_label.add_theme_font_size_override("font_size", 14)

func _process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var shader_material = camera._material
	
	# Get debug values from shader
	var debug_t = shader_material.get_shader_parameter("v_debug_t")
	var debug_d = shader_material.get_shader_parameter("v_debug_d")
	var debug_steps = shader_material.get_shader_parameter("v_debug_steps")
	var debug_normal = shader_material.get_shader_parameter("v_debug_normal")
	var debug_pos = shader_material.get_shader_parameter("v_debug_pos")
	var debug_shape_id = shader_material.get_shader_parameter("v_debug_shape_id")
	
	# Format debug info
	var info = """
	Mouse Position: {mouse_x}, {mouse_y}
	Distance Traveled (t): {t}
	Surface Distance (d): {d}
	Ray Steps: {steps}
	Normal: {normal}
	Hit Position: {pos}
	Shape ID: {shape_id}
	""".format({
		"mouse_x": mouse_pos.x,
		"mouse_y": mouse_pos.y,
		"t": debug_t,
		#"d": debug_d,
		#"steps": debug_steps,
		"normal": debug_normal,
		"pos": debug_pos,
		"shape_id": debug_shape_id
	})
	
	info_label.text = info
	
	# Position label near mouse but ensure it stays on screen
	var label_pos = mouse_pos + Vector2(20, 20)
	var viewport_size = get_viewport().size
	if label_pos.x + info_label.size.x > viewport_size.x:
		label_pos.x = viewport_size.x - info_label.size.x
	if label_pos.y + info_label.size.y > viewport_size.y:
		label_pos.y = viewport_size.y - info_label.size.y
		
	info_label.position = label_pos
