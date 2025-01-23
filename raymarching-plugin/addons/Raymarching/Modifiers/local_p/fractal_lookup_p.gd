# fractal_lookup_modifier.gd
class_name FractalLookupModifier_p
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
	vec3 get_effect_space(vec3 pos, vec3 effect_dir, float falloff_dist) {
		float dist = length(pos);
		float falloff = smoothstep(falloff_dist, 0.0, dist);
		return pos * normalize(effect_dir) * falloff;
	}

	vec3 get_fractal_field(vec3 z, vec2 c, float time) {
		vec3 offset = vec3(0.0);
		float amp = 1.0;
		vec3 seed = z;
		
		for(int i = 0; i < 4; i++) {
			// Apply fractal iteration to all components
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
		
		// 3D flow movement
		offset += vec3(
			sin(seed.x * 2.0 + time),
			cos(seed.y * 2.0 + time),
			sin(seed.z * 2.0 + time * 0.7)
		) * 0.25;
		
		return offset;
	}

	vec3 get_pattern_blend(vec3 z, float time) {
		vec2 c1 = vec2(0.38, 0.28);
		vec2 c2 = vec2(-0.4, 0.6);
		vec2 c_blend = mix(c1, c2, (sin(time * 0.2) + 1.0) * 0.5);
		
		return get_fractal_field(z, c_blend, time);
	}

	vec3 get_turbulent_displacement(vec3 pos, float scale, float time, float turbulence, vec3 effect_dir, float falloff_dist) {
		vec3 effect_pos = get_effect_space(pos, effect_dir, falloff_dist);
		vec3 sample_pos = effect_pos / scale;
		
		vec3 displacement = vec3(0.0);
		float amp = 1.0;
		
		for(int i = 0; i < 3; i++) {
			displacement += amp * get_pattern_blend(sample_pos, time);
			sample_pos *= 2.17;
			amp *= turbulence;
		}
		
		return displacement * effect_dir;
	}
	"""

func get_p_modifier_template() -> String:
	return """
	vec3 displacement = get_turbulent_displacement(
		p,
		{fractal_scale},
		TIME * {flow_speed},
		{turbulence},
		{effect_axis},
		{falloff_distance}
	);
	
	vec3 result = p + displacement * {influence_strength};
	"""

func get_d_modifier_template() -> String:
	return ""  # No longer modifying d directly
