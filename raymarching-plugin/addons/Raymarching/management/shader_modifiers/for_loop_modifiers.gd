class_name RaymarchModifiers

# Static Nil instance
static var NIL = null

# In RaymarchModifiers class
func to_shader_params() -> Dictionary:
	return {
		"ro_mul": ro_mul,
		"rd_mul": rd_mul,
		"pos_mul": pos_mul,
		"surf_mul": surf_mul,
		"max_mul": max_mul,
		"ro_add": ro_add,
		"rd_add": rd_add,
		"pos_add": pos_add,
		"surf_add": surf_add,
		"max_add": max_add
	}

# Default values are already set in the class variables

static func _static_init():
	NIL = RaymarchModifiers.new()

# Multiplicative modifiers
var ro_mul: Vector3 = Vector3.ONE
var rd_mul: Vector3 = Vector3.ONE
var pos_mul: Vector3 = Vector3.ONE
var surf_mul: float = 1.0
var max_mul: float = 1.0

# Additive modifiers
var ro_add: Vector3 = Vector3.ZERO
var rd_add: Vector3 = Vector3.ZERO
var pos_add: Vector3 = Vector3.ZERO
var surf_add: float = 0.0
var max_add: float = 0.0

func _init():
	reset_to_nil()

func reset_to_nil() -> void:
	ro_mul = Vector3.ONE
	rd_mul = Vector3.ONE
	pos_mul = Vector3.ONE
	surf_mul = 1.0
	max_mul = 1.0
	ro_add = Vector3.ZERO
	rd_add = Vector3.ZERO
	pos_add = Vector3.ZERO
	surf_add = 0.0
	max_add = 0.0

func is_nil() -> bool:
	return (
		ro_mul == Vector3.ONE and
		rd_mul == Vector3.ONE and
		pos_mul == Vector3.ONE and
		surf_mul == 1.0 and
		max_mul == 1.0 and
		ro_add == Vector3.ZERO and
		rd_add == Vector3.ZERO and
		pos_add == Vector3.ZERO and
		surf_add == 0.0 and
		max_add == 0.0
	)
