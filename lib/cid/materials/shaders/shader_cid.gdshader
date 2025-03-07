shader_type spatial;
render_mode unshaded;

uniform sampler2D stars_texture: filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(4.0, 2.0);
uniform vec3 modulate: source_color = vec3(0.75);

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(
		dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(stars_texture, SCREEN_UV * uv_scale).rgb * modulate;
	ALBEDO += ALBEDO * fresnel(2.0, NORMAL, VIEW) * 5.0;
	ALPHA -= (1.0 - clamp(fresnel(0.4, NORMAL, VIEW), 0.0, 1.0)) * 0.5;
}
