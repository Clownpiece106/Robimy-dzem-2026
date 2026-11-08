shader_type canvas_item;
render_mode unshaded;

void fragment() {
	if (SCREEN_UV.x < 0.5) {
		COLOR.rgb = vec3(1.0) - COLOR.rgb;
	}
}
