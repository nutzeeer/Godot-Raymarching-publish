# fractal_lookup_modifier.gd
class_name FractalLookupModifier_p2
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "influence_strength",
		"type": TYPE_FLOAT,
		"default": 0.5,
		"min": 0.0,
		"max": 1.0,
		"description": "Strength of the fractal influence"
	},
	{
		"name": "fractal_scale",
		"type": TYPE_FLOAT,
		"default": 2.0,
		"min": 0.1,
		"max": 10.0,
		"description": "Scale of the fractal sampling"
	},
	{
		"name": "flow_speed",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 10.0,
		"description": "Speed of pattern flow"
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
		"name": "effect_axis",
		"type": TYPE_VECTOR3,
		"default": Vector3(1.0, 1.0, 0.0),
		"description": "Primary axes for fractal effect"
	},
	{
		"name": "falloff_distance",
		"type": TYPE_FLOAT,
		"default": 1.0,
		"min": 0.0,
		"max": 10.0,
		"description": "Distance-based effect falloff"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS
	
func get_pre_map_functions() -> String:
	return """
	vec3 get_shape_centered_position(vec3 world_pos, mat4 shape_transform) {
		// Convert world position to shape-relative position
		vec3 shape_origin = (shape_transform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		return world_pos - shape_origin;
	}

	vec3 get_effect_space(vec3 pos, mat4 shape_transform, vec3 effect_dir, float falloff_dist) {
		// Convert to shape-relative space
		vec3 relative_pos = get_shape_centered_position(pos, shape_transform);
		
		// Apply shape's rotation to effect direction
		vec3 rotated_effect_dir = mat3(shape_transform) * normalize(effect_dir);
		
		float dist = length(relative_pos);
		float falloff = smoothstep(falloff_dist, 0.0, dist);
		
		// Project onto rotated effect direction
		return relative_pos * rotated_effect_dir * falloff;
	}

	vec3 get_fractal_field(vec3 z, vec2 c, float time, mat4 shape_transform) {
		vec3 offset = vec3(0.0);
		float amp = 1.0;
		vec3 seed = z;
		
		// Orient sampling space with shape
		mat3 rotation = mat3(shape_transform);
		z = rotation * z;
		
		for(int i = 0; i < 4; i++) {
			z = vec3(
				z.x * z.x - z.y * z.y,
				2.0 * z.x * z.y,
				z.z * z.z - z.x * z.x
			) + vec3(c, 0.0);
			
			float len = length(z);
			offset += amp * z * smoothstep(4.0, 0.0, len);
			amp *= 0.5;
			
			if(len > 4.0) break;
		}
		
		// Flow movement oriented with shape
		vec3 flow = vec3(
			sin(seed.x * 2.0 + time),
			cos(seed.y * 2.0 + time),
			sin(seed.z * 2.0 + time * 0.7)
		) * 0.25;
		
		return rotation * (offset + flow);
	}

	vec3 get_pattern_blend(vec3 z, float time, mat4 shape_transform) {
		vec2 c1 = vec2(0.38, 0.28);
		vec2 c2 = vec2(-0.4, 0.6);
		vec2 c_blend = mix(c1, c2, (sin(time * 0.2) + 1.0) * 0.5);
		
		return get_fractal_field(z, c_blend, time, shape_transform);
	}

	vec3 get_turbulent_displacement(vec3 pos, mat4 shape_transform, float scale, float time, float turbulence, vec3 effect_dir, float falloff_dist) {
		vec3 effect_pos = get_effect_space(pos, shape_transform, effect_dir, falloff_dist);
		vec3 sample_pos = effect_pos / scale;
		
		vec3 displacement = vec3(0.0);
		float amp = 1.0;
		
		for(int i = 0; i < 3; i++) {
			displacement += amp * get_pattern_blend(sample_pos, time, shape_transform);
			sample_pos *= 2.17;
			amp *= turbulence;
		}
		
		return mat3(shape_transform) * displacement;
	}
	"""

func get_p_modifier_template() -> String:
	return """
	vec3 displacement = get_turbulent_displacement(
		p,
		shape%s_transform,
		{fractal_scale},
		TIME * {flow_speed},
		{turbulence},
		{effect_axis},
		{falloff_distance}
	);
	
	vec3 result = p + displacement * {influence_strength};
	""" % get_modifier_id()

func get_d_modifier_template() -> String:
	return ""  # No longer modifying d directly
