shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec2 amplitude = vec2(0.2, 0.1);
uniform vec2 amplitude2 = vec2(0.1, 0.2);
uniform vec2 frequency = vec2(3.0, 2.5);
uniform vec2 frequency2 = vec2(0.5, -1.5);
uniform vec2 time_factor = vec2(3.0, 2.5);
uniform vec2 time_factor2 = vec2(1.0, 2.0);

uniform sampler2D texturemap : source_color;
uniform vec2 texture_scale = vec2(30.0, 30.0);

uniform vec2 texture_flow1 = vec2(0.5, 0.25);
uniform vec2 texture_flow2 = vec2(-0.5, 1.0);

float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x*frequency.x + time*time_factor.x)) + (amplitude.y * sin(pos.y*frequency.y + time*time_factor.y)) + (amplitude2.x * sin(pos.x*frequency2.x + time*time_factor2.x)) + (amplitude2.y * sin(pos.y*frequency2.y + time*time_factor2.y)) / 2.0;
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME);
	
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0), TIME) - height(VERTEX.xz + vec2(-0.2, 0), TIME), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() {
	ALBEDO = (texture(texturemap, UV * texture_scale + TIME * texture_flow1) + 0.25 * texture(texturemap, UV * texture_scale + TIME * texture_flow2)).rgb;
	
	if (ALBEDO.r > 0.9 && ALBEDO.g > 0.9 && ALBEDO.b > 0.9) {
		ALPHA = 0.9;
	} else {
		ALPHA = 0.5;
	}
	
	METALLIC = 0.5;
	ROUGHNESS = 0.4;
}
