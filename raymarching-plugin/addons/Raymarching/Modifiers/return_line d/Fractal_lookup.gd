# fractal_lookup_modifier.gd
class_name FractalLookupModifier
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
	float get_fractal_field(vec2 z, vec2 c, float time) {
		float v = 0.0;
		float amp = 1.0;
		vec2 seed = z;
		
		// Only need 4-5 iterations for good patterns
		for(int i = 0; i < 4; i++) {
			z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
			float len = dot(z,z);
			
			// Accumulate smooth pattern values
			v += amp * smoothstep(0.0, 4.0, len);
			amp *= 0.5;
			
			// Early bail for efficiency
			if(len > 4.0) break;
		}
		
		// Add flow movement
		return v + sin(seed.x * 2.0 + time) * cos(seed.y * 2.0 + time) * 0.25;
	}

	// Multi-scale sampling for richer patterns
	float get_turbulent_field(vec2 pos, float scale, float time, float turbulence) {
		float pattern = 0.0;
		float amp = 1.0;
		
		// Sample at multiple scales
		for(int i = 0; i < 3; i++) {
			vec2 c = vec2(0.38, 0.28); // Interesting Julia set parameter
			pattern += amp * get_fractal_field(pos * scale, c, time);
			pos *= 2.17; // Non-integer scale for more natural look
			amp *= turbulence;
		}
		
		return pattern;
	}
	"""

func get_d_modifier_template() -> String:
	return """
	// Get base coordinates for sampling
	vec2 base_pos = local_p.xy / {fractal_scale};
	
	// Calculate time-varying pattern
	float pattern = get_turbulent_field(
		base_pos,
		1.0,
		TIME * {flow_speed},
		{turbulence}
	);
	
	// Apply pattern to distance field
	float effect = pattern * {influence_strength};
	d *= 1.0 + effect;
	"""
