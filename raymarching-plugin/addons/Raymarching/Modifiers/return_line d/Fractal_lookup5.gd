# fractal_lookup_modifier.gd
class_name FractalLookupModifier5
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
	vec3 get_effect_space(vec3 pos, mat4 shape_transform, vec3 effect_dir, float falloff_dist) {
		vec3 local = (inverse(shape_transform) * vec4(pos, 1.0)).xyz;
		float dist = length(local);
		float falloff = smoothstep(falloff_dist, 0.0, dist);
		
		// Project onto effect plane
		vec3 projected = local * normalize(effect_dir);
		return projected * falloff;
	}

	float get_fractal_field(vec2 z, vec2 c, float time, mat4 shape_transform) {
		float v = 0.0;
		float amp = 1.0;
		vec2 seed = z;
		
		for(int i = 0; i < 4; i++) {
			z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
			float len = dot(z,z);
			v += amp * smoothstep(0.0, 4.0, len);
			amp *= 0.5;
			if(len > 4.0) break;
		}
		
		// Add pattern evolution
		float pattern_evolution = sin(length(z) - time * 0.5) * 0.2;
		float orbit_trap = length(z - vec2(sin(time), cos(time)));
		v = mix(v, orbit_trap, pattern_evolution);
		
		return v + sin(seed.x * 2.0 + time) * cos(seed.y * 2.0 + time) * 0.25;
	}

	float get_pattern_blend(vec2 z, float time, mat4 shape_transform) {
		vec2 c1 = vec2(0.38, 0.28);
		vec2 c2 = vec2(-0.4, 0.6);
		vec2 c_blend = mix(c1, c2, (sin(time * 0.2) + 1.0) * 0.5);
		
		return get_fractal_field(z, c_blend, time, shape_transform);
	}

	float get_turbulent_field(vec3 pos, float scale, float time, float turbulence, mat4 shape_transform, vec3 effect_dir, float falloff_dist) {
		vec3 effect_pos = get_effect_space(pos, shape_transform, effect_dir, falloff_dist);
		vec2 sample_pos = effect_pos.xy / scale;
		
		float pattern = 0.0;
		float amp = 1.0;
		
		for(int i = 0; i < 3; i++) {
			pattern += amp * get_pattern_blend(sample_pos, time, shape_transform);
			sample_pos *= 2.17;
			amp *= turbulence;
		}
		
		return pattern;
	}
	"""

func get_d_modifier_template() -> String:
	return """
	float pattern = get_turbulent_field(
		local_p,
		{fractal_scale},
		TIME * {flow_speed},
		{turbulence},
		shape%s_transform,
		{effect_axis},
		{falloff_distance}
	);
	
	float effect = pattern * {influence_strength};
	d *= 1.0 + effect;
	""" % get_modifier_id()
