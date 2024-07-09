shader_type spatial;

uniform sampler2D full_tex;

uniform float percentage;

void fragment() {
	if(UV.x < percentage) {
		ALBEDO = texture(full_tex, UV).rgb;
	} else {
		ALBEDO = vec3(0, 0, 0);
		ALPHA = 0.0;
	}
}
