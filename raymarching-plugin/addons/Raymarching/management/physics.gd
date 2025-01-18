extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


// Schritt 5: Vollständige Integration mit allen Parametern
float integrate_complete(vec4 p4d, float sdf_3d(vec3)) {
	float t = p4d.w;
	vec3 p = p4d.xyz;
	
	// Translation mit allen Kräften
	vec3 gravity_acc = vec3(0.0, -9.81 * gravity_scale / mass, 0.0);
	
	// Friction als Dämpfung der Geschwindigkeit
	vec3 damped_velocity = linear_velocity * exp(-friction * t);
	
	// Bounce würde bei Kollisionen die Geschwindigkeit beeinflussen
	// (wird erst bei der Kollisionsbehandlung relevant)
	
	vec3 translation = initial_position + 
					  damped_velocity * t + 
					  0.5 * gravity_acc * t * t;
	
	// Rotation mit allen Einflüssen
	vec3 damped_angular = angular_velocity * exp(-friction * t);
	vec3 adjusted_angular_vel = damped_angular / (inertia * mass);
	vec3 rotation = initial_rotation + adjusted_angular_vel * t;
	
	return sdf_3d(rotate(p - translation, -rotation));
}


vec4 gradient_complete(vec4 p4d, float sdf_3d(vec3)) {
	float dt = 0.0001; // kleiner Zeitschritt für numerische Ableitung
	
	// Partielle Ableitungen approximieren
	float dx = (integrate_complete(p4d + vec4(dt,0,0,0), sdf_3d) - 
				integrate_complete(p4d - vec4(dt,0,0,0), sdf_3d)) / (2.0*dt);
				
	float dy = (integrate_complete(p4d + vec4(0,dt,0,0), sdf_3d) - 
				integrate_complete(p4d - vec4(0,dt,0,0), sdf_3d)) / (2.0*dt);
				
	float dz = (integrate_complete(p4d + vec4(0,0,dt,0), sdf_3d) - 
				integrate_complete(p4d - vec4(0,0,dt,0), sdf_3d)) / (2.0*dt);
				
	float dtm = (integrate_complete(p4d + vec4(0,0,0,dt), sdf_3d) - 
				 integrate_complete(p4d - vec4(0,0,0,dt), sdf_3d)) / (2.0*dt);
	
	return vec4(dx, dy, dz, dtm);
}


vec4 trace_path(vec4 start, float sdf_3d(vec3), float duration, float dt) {
	vec4 p = start;
	for(float t = 0.0; t < duration; t += dt) {
		vec4 grad = gradient_complete(p, sdf_3d);
		p += dt * grad;
		// Hier können wir p ausgeben oder in einem Array sammeln 
	}
	return p; // Endpunkt zurückgeben
}
