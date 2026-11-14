shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float opacity = 0.22;
void fragment() {
	vec2 delta = (UV-vec2(0.5))*2.0;
	float feather = pow(max(0.0,1.0-dot(delta,delta)),2.0);
	ALBEDO=vec3(0.12,0.085,0.045);
	ALPHA=feather*opacity;
}
