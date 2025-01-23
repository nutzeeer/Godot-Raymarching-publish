# physics_fractal_modifier.gd
class_name PhysicsFractalModifier
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	# Physics parameters
	{
		"name": "velocity",
		"type": TYPE_VECTOR3,
		"default": Vector3.ZERO,
		"description": "Current velocity of object"
	},
	{
		"name": "field_size",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.1,
		"max": 10.0,
		"description": "Size of influence field"
	},
	{
		"name": "field_strength",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 10.0,
		"description": "Strength of field influence"
	},
	# Fractal parameters
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
	},# Add these parameters to MODIFIER_PARAMETERS
	{
		"name": "gravity",
		"type": TYPE_VECTOR3,
		"default": Vector3(0, -9.81, 0),
		"description": "Gravity vector"
	},
	{
		"name": "initial_velocity",
		"type": TYPE_VECTOR3,
		"default": Vector3.ZERO,
		"description": "Starting velocity"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_pre_map_functions() -> String:
	return """
	float evaluate_physics_field(vec3 p, vec3 center, vec3 velocity, float field_size) {
		vec3 relative_p = p - center;
		float field_distance = length(relative_p);
		float vel_magnitude = length(velocity);
		
		return smoothstep(field_size, 0.0, field_distance) * vel_magnitude;
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



# Then in get_p_modifier_template():
func get_p_modifier_template() -> String:
	return """
	// Calculate time-based velocity with gravity
	vec3 current_velocity = {initial_velocity} + {gravity} * TIME;
	
	vec3 object_center = (shape%s_transform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float field = evaluate_physics_field(p, object_center, current_velocity, {field_size});
	
	vec3 fractal_deform = get_velocity_aligned_fractal(
		p, 
		current_velocity, 
		{fractal_scale},
		{turbulence},
		TIME
	);
	
	// Combine field and fractal effects
	vec3 deformation = fractal_deform * field * {field_strength} * {deform_strength};
	vec3 result = p + deformation;
	""" % get_modifier_id()

func get_d_modifier_template() -> String:
	return ""  # Using position modification only for now
