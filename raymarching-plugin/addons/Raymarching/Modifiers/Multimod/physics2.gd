# physics_fractal_modifier.gd
class_name PhysicsFractalModifier2
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "gravity_strength",
		"type": TYPE_FLOAT,
		"default": 9.81,
		"min": 0.0,
		"max": 20.0,
		"description": "Strength of gravitational acceleration"
	},
	{
		"name": "fractal_scale",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.1,
		"max": 10.0,
		"description": "Scale of fractal deformation"
	},
	{
		"name": "turbulence",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 2.0,
		"description": "Amount of turbulent variation"
	},
	{
		"name": "deform_strength",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 5.0,
		"description": "Overall deformation strength"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_pre_map_functions() -> String:
	return """
	vec3 calculate_motion(vec3 p, float t, float g) {
		// Basic parabolic motion
		return vec3(0.0, -0.5 * g * t * t, 0.0);
	}
	
	vec3 get_velocity(float t, float g) {
		return vec3(0.0, -g * t, 0.0);
	}
	
	vec3 get_velocity_aligned_fractal(vec3 p, vec3 velocity, float scale, float turbulence, float time) {
		// Align fractal with velocity direction
		vec3 vel_dir = normalize(velocity + vec3(0.0001));
		mat3 align_basis;
		
		// Create basis aligned with velocity
		align_basis[2] = vel_dir;
		align_basis[0] = normalize(cross(vel_dir, vec3(0.0, 1.0, 0.0)));
		align_basis[1] = cross(align_basis[2], align_basis[0]);
		
		// Sample fractal in aligned space
		vec3 aligned_p = transpose(align_basis) * p;
		vec3 fractal = vec3(0.0);
		float amp = 1.0;
		
		for(int i = 0; i < 3; i++) {
			vec3 sample_pos = aligned_p * scale + time * vel_dir;
			fractal += amp * vec3(
				sin(sample_pos.x + sample_pos.y),
				cos(sample_pos.y + sample_pos.z),
				sin(sample_pos.z + sample_pos.x)
			);
			aligned_p *= 2.17;
			amp *= turbulence;
		}
		
		// Transform back to world space
		return align_basis * fractal;
	}
	"""

func get_p_modifier_template() -> String:
	return """
	// Calculate analytical motion
	vec3 motion = calculate_motion(p, sin(TIME), {gravity_strength});
	vec3 current_velocity = get_velocity(TIME, {gravity_strength});
	
	// Apply motion to position
	vec3 physics_p = p + motion;
	
	// Use velocity for fractal deformation direction
	vec3 fractal_deform = get_velocity_aligned_fractal(
		physics_p,
		current_velocity,
		{fractal_scale},
		{turbulence},
		TIME
	);
	
	vec3 result = physics_p + fractal_deform * {deform_strength};
	"""

func get_d_modifier_template() -> String:
	return ""  # Using position modification only
