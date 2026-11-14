shader_type spatial;
uniform sampler2D surface_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform int surface_kind = 0;
varying vec3 point;
varying vec3 face_normal;
void vertex(){
	point = VERTEX;
	face_normal = NORMAL;
}
void fragment(){
	vec3 n = abs(normalize(face_normal));
	vec2 p = n.y > 0.65 ? point.xz : (n.z > n.x ? point.xy : point.zy);
	vec2 uv = p * (surface_kind == 1 || surface_kind == 2 ? vec2(0.38,0.6) : vec2(1.0));
	vec3 sample_color = texture(surface_tex, uv).rgb;
	if(surface_kind == 1 || surface_kind == 2){
		ALBEDO = mix(tint.rgb, sample_color, 0.35) * 0.65;
		if(surface_kind == 2 && n.y > 0.65){
			float board = floor(p.x * 3.5);
			float seam = smoothstep(0.0,0.012,min(fract(p.x*3.5),1.0-fract(p.x*3.5)));
			float join = smoothstep(0.0,0.006,min(fract(p.y*0.7+board*0.37),1.0-fract(p.y*0.7+board*0.37)));
			ALBEDO *= 0.72 + 0.28*min(seam,join);
		}
		ROUGHNESS = surface_kind == 1 ? 0.48 : 0.72;
		SPECULAR = 0.35;
	}else{
		float grain = dot(sample_color,vec3(0.333));
		ALBEDO = tint.rgb * (0.67 + grain * 0.55);
		ROUGHNESS = 0.94;
		SPECULAR = 0.12;
	}
}
