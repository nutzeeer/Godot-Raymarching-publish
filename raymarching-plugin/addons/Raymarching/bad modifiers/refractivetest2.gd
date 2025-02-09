class_name ChromaticRefractionModifier21
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "ior",
		"type": TYPE_FLOAT,
		"default": 1.5,
		"min": 1.0,
		"max": 3.0,
		"description": "Base index of refraction"
	},
	{
		"name": "aberration",
		"type": TYPE_FLOAT,
		"default": 0.01,
		"min": 0.0,
		"max": 0.1,
		"description": "Chromatic aberration strength"
	},
	{
		"name": "density",
		"type": TYPE_FLOAT,
		"default": 0.1,
		"min": 0.0,
		"max": 1.0,
		"description": "Material density for absorption"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_utility_functions() -> String:
	return """
	float calculate_fresnel(vec3 incident, vec3 normal) {
		return pow(1.0 + dot(incident, normal), 5.0);
	}
	
	vec3 get_refracted_color(vec3 rd_in, vec3 normal, float ior, float aberration) {
		vec3 refracted_color;
		
		// Red channel
		vec3 rd_out = refract(rd_in, normal, ior - aberration);
		refracted_color.r = (dot(rd_out, rd_out) > 0.0) ? rd_out.x * 0.5 + 0.5 : reflect(rd_in, normal).x * 0.5 + 0.5;
		
		// Green channel
		rd_out = refract(rd_in, normal, ior);
		refracted_color.g = (dot(rd_out, rd_out) > 0.0) ? rd_out.y * 0.5 + 0.5 : reflect(rd_in, normal).y * 0.5 + 0.5;
		
		// Blue channel
		rd_out = refract(rd_in, normal, ior + aberration);
		refracted_color.b = (dot(rd_out, rd_out) > 0.0) ? rd_out.z * 0.5 + 0.5 : reflect(rd_in, normal).z * 0.5 + 0.5;
		
		return refracted_color;
	}
	"""

func get_forloop_modifier_template() -> String:
	return """
	if (d > 0.0 && d < current_accuracy) {  // Entering surface
		vec3 normal = getNormal(pos);
		vec3 reflected = reflect(current_rd, normal);
		
		// Calculate entrance refraction
		vec3 rd_in = refract(current_rd, normal, 1.0/{ior});
		if(dot(rd_in, rd_in) > 0.0) {  // Valid refraction
			// Step inside slightly
			vec3 p_enter = pos - normal * current_accuracy * 3.0;
			
			// March through interior
			vec3 p_temp = p_enter;
			float d_internal = 0.0;
			
			// Simple fixed-step march through interior
			for(int i = 0; i < 50; i++) {
				p_temp += rd_in * current_accuracy;
				float d_temp = map_refractive(p_temp);
				if(d_temp > 0.0) {  // Found exit point
					vec3 n_exit = -getNormal(p_temp);
					
					// Get refracted color with dispersion
					vec3 refracted_color = get_refracted_color(rd_in, n_exit, {ior}, {aberration});
					
					// Apply absorption based on path length
					float absorption = exp(-d_internal * {density});
					ALBEDO = mix(ALBEDO, refracted_color * absorption, 0.5);
					
					// Update ray direction and continue marching
					current_rd = refract(rd_in, n_exit, {ior});
					if(dot(current_rd, current_rd) == 0.0) current_rd = reflect(rd_in, n_exit);
					
					t += d_internal + current_accuracy * 4.0 ;
					break;
				}
				d_internal += current_accuracy;
			}
		}
		
		// Apply fresnel for reflection vs refraction mix
		float fresnel = calculate_fresnel(current_rd, normal);
		ALBEDO = mix(ALBEDO, reflected * 0.5 + 0.5, fresnel);
		
		continue;
	}
	
	t += d;
	"""

func get_custom_map_name() -> String:
	return "map_refractive"
