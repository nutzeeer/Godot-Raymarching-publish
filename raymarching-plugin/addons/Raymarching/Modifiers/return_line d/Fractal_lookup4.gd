# fractal_lookup_modifier.gd
class_name FractalLookupModifier4
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
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_pre_map_functions() -> String:
	return """
	// Optimized Julia/Mandelbrot hybrid for fast pattern generation
	float get_fractal_field(vec2 z, vec2 c, float time, mat4 shape_transform) {
		// Transform input coordinates using shape transform
		vec3 transformed_pos = (shape_transform * vec4(z.x, z.y, 0.0, 1.0)).xyz;
		z = transformed_pos.xy;
		
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
		
		return v + sin(seed.x * 2.0 + time) * cos(seed.y * 2.0 + time) * 0.25;
	}

	float get_turbulent_field(vec2 pos, float scale, float time, float turbulence, mat4 shape_transform) {
		float pattern = 0.0;
		float amp = 1.0;
		
		for(int i = 0; i < 3; i++) {
			vec2 c = vec2(0.38, 0.28);
			pattern += amp * get_fractal_field(pos * scale, c, time, shape_transform);
			pos *= 2.17;
			amp *= turbulence;
		}
		
		return pattern;
	}
	"""

func get_d_modifier_template() -> String:
	return """
	vec2 base_pos = local_p.xy / {fractal_scale};
	
	float pattern = get_turbulent_field(
		base_pos,
		1.0,
		TIME * {flow_speed},
		{turbulence},
		shape%s_transform
	);
	
	float effect = pattern * {influence_strength};
	d *= 1.0 + effect;
	""" % get_modifier_id()
