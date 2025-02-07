# refractive_modifier.gd
class_name RefractiveModifiercolor
extends GeneralModifierBase

const MODIFIER_PARAMETERS = [
	{
		"name": "ior",
		"type": TYPE_FLOAT,
		"default": 1.45,
		"min": 1.0,
		"max": 3.0,
		"description": "Index of refraction"
	},
	{
		"name": "aberration",
		"type": TYPE_FLOAT,
		"default": 0.02,
		"min": 0.0,
		"max": 0.1,
		"description": "Chromatic aberration strength"
	}
]

func get_modifier_parameters() -> Array:
	return MODIFIER_PARAMETERS

func get_custom_map_name() -> String:
	return "map_refractive"

func get_custom_map_template() -> String:
	return """
float map_refractive(vec3 p) {
	float final_distance = MAX_DISTANCE;
	${SHAPES_CODE}
	return final_distance;
}
"""

func get_color_modifier_template() -> String:
	return """
	float d_refr = map_refractive(pos);
	if (abs(d_refr) < current_accuracy) {
		vec3 reflected = reflect(current_rd, normal);
		vec3 refOutside = reflected * 0.5 + 0.5;  // Simple environment approximation
		
		// Calculate entry refraction
		vec3 pEnter = pos - normal * current_accuracy * 4.0;
		vec3 rdIn = refract(current_rd, normal, 1.0/{ior});
		
		if (dot(rdIn, rdIn) > 0.0) {  // Valid refraction
			// March through interior
			float dIn = 0.0;
			vec3 pTemp = pEnter;
			bool found_exit = false;
			
			for (int i = 0; i < MAX_STEPS/2; i++) {
				float d = map_refractive(pTemp);
				if (d > current_accuracy) {
					found_exit = true;
					break;
				}
				pTemp += rdIn * d;
				dIn += d;
				if (dIn > MAX_DISTANCE) break;
			}
			
			if (found_exit) {
				vec3 pExit = pTemp;
				vec3 nExit = -getNormal(pExit);
				vec3 reflTex = vec3(0.0);
				
				// Red channel
				vec3 rdOut = refract(rdIn, nExit, {ior} - {aberration});
				if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
				reflTex.r = rdOut.x * 0.5 + 0.5;
				
				// Green channel
				rdOut = refract(rdIn, nExit, {ior});
				if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
				reflTex.g = rdOut.y * 0.5 + 0.5;
				
				// Blue channel
				rdOut = refract(rdIn, nExit, {ior} + {aberration});
				if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
				reflTex.b = rdOut.z * 0.5 + 0.5;
				
				float fresnel = pow(1.0 + dot(current_rd, normal), 5.0);
				ALBEDO = mix(reflTex, refOutside, fresnel);
			}
		}
	}
	"""
