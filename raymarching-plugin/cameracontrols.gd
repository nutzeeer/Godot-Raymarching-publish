extends Node3D

@export var mouse_sensitivity: float = 0.3
@export var fly_speed: float = 5.0
@export var fast_speed: float = 10.0
@export var fly_smooth: float = 0.3

var camera_rotation = Vector3()
var current_speed = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)




func _process(delta):
	# Get the camera's forward and right vectors
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	
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
	
	# Smoothly interpolate speed
	current_speed = lerp(current_speed, target_speed, fly_smooth)
	
	# Apply movement in global space
	position += movement * current_speed * delta
