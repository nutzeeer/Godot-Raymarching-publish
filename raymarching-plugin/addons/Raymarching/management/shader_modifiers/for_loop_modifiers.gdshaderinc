struct RayModifiers {
    vec3 ro_mul, rd_mul, pos_mul;
    float surf_mul, max_mul;
    vec3 ro_add, rd_add, pos_add;
    float surf_add, max_add;
};

float apply_modifier(float base_value, float add_mod, float mul_mod) {
    return (base_value + add_mod) * mul_mod;
}

vec3 apply_modifier_vec3(vec3 base_value, vec3 add_mod, vec3 mul_mod) {
    return (base_value + add_mod) * mul_mod;
}

// Preset modifier functions
RayModifiers get_default_modifiers() {
    return RayModifiers(
        vec3(1.0), vec3(1.0), vec3(1.0), 1.0, 1.0,  // mul
        vec3(0.0), vec3(0.0), vec3(0.0), 0.0, 0.0   // add
    );
}

RayModifiers get_gravity_well_modifiers(float strength) {
    RayModifiers mods = get_default_modifiers();
    mods.rd_mul = vec3(1.0 - strength);
    mods.pos_mul = vec3(1.0 + strength);
    return mods;
}

RayModifiers get_fisheye_modifiers(float distortion) {
    RayModifiers mods = get_default_modifiers();
    mods.rd_mul = vec3(1.0 + distortion);
    mods.pos_add = vec3(0.0, 0.0, distortion);
    return mods;
}

RayModifiers get_atmospheric_modifiers(float density) {
    RayModifiers mods = get_default_modifiers();
    mods.max_mul = 1.0 - density;
    mods.surf_mul = 1.0 + density;
    return mods;
}

RayModifiers get_vortex_modifiers(float twist) {
    RayModifiers mods = get_default_modifiers();
    mods.rd_mul = vec3(1.0 + twist);
    mods.pos_mul = vec3(1.0 - twist * 0.5);
    return mods;
}