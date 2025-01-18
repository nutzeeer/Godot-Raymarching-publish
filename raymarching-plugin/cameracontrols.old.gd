extends Node3D

@export var mouse_sensitivity: float = 0.001
@export var fly_speed: float = 5.0
@export var fast_speed: float = 10.0
@export var fly_smooth: float = 0.3
@export var sdf_influence: float = 1.0

var camera_rotation = Vector3()
var current_speed = 0.0
@onready var raymarch_camera = get_child(0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Get the shader code from the camera's material
	var material = raymarch_camera._material
	var shader = material.shader
	var code = shader.code
	
	if not "uniform vec2 center_uv;" in code:
		# Add uniform for center UV coordinates
		var uniform_pos = code.find("uniform")
		code = code.insert(uniform_pos, "uniform vec2 center_uv;\n")
		
		# Add distance output in fragment shader
		var fragment_pos = code.find("void fragment()")
		var opening_brace_pos = code.find("{", fragment_pos)
		var distance_output = """
	float stored_distance = 0.0;
	
	// Process raymarching
"""
		code = code.insert(opening_brace_pos + 1, distance_output)
		
		# Add center pixel check after the raymarching loop
		var lighting_pos = code.find("// Calculate lighting")
		var if_statement = """
	// Store distance for center pixel
	if (SCREEN_UV == center_uv) {
		stored_distance = t;
	}
"""
		code = code.insert(lighting_pos, if_statement)
		
		shader.code = code
		material.shader = shader
		
		# Set center UV coordinates
		material.set_shader_parameter("center_uv", Vector2(0.5, 0.5))

func _input(event):
	if event is InputEventMouseMotion:
		var motion = event.relative
		rotation.x -= motion.y * mouse_sensitivity
		rotation.y -= motion.x * mouse_sensitivity
		# Optional: Clamp vertical rotation to prevent over-rotation
		rotation.x = clamp(rotation.x, -PI/2, PI/2)  # Clamp to 90 degrees up/down
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# Get the camera's forward and right vectors
	var forward = -global_transform.basis.z
	var right = +global_transform.basis.x
	# Initialize movement vector
	var movement = Vector3.ZERO
	
	# Add movement based on input
	if Input.is_key_pressed(KEY_W):
		movement += forward 
	if Input.is_key_pressed(KEY_S):
		movement -= forward
	if Input.is_key_pressed(KEY_D):
		movement += right
	if Input.is_key_pressed(KEY_A):
		movement -= right
	if Input.is_key_pressed(KEY_SPACE):
		movement += Vector3.UP
	if Input.is_key_pressed(KEY_SHIFT):
		movement -= Vector3.UP
	
	# Normalize the movement vector if we're moving
	if movement.length_squared() > 0:
		movement = movement.normalized()
	
	# Set speed based on alt key
	var target_speed = fly_speed
	if Input.is_key_pressed(KEY_ALT):
		target_speed = fast_speed
		
	# Get distance from stored value if available
	if raymarch_camera._material:
		var center_dist = raymarch_camera._material.get_shader_parameter("stored_distance")
		if center_dist != null:
			var dist_multiplier = clamp(center_dist * sdf_influence, 0.1, 2.0)
			target_speed *= dist_multiplier
	
	# Smoothly interpolate speed
	current_speed = lerp(current_speed, target_speed, fly_smooth)
	
	# Apply movement in global space
	position += movement * current_speed * delta
