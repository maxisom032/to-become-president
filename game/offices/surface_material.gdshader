shader_type spatial;
uniform sampler2D surface_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform int surface_kind = 0;
uniform int wallpaper = 0;
varying vec3 point;
varying vec3 world_point;
varying vec3 face_normal;
void vertex(){
	point = VERTEX;
	world_point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	face_normal = NORMAL;
}
void fragment(){
	vec3 n = abs(normalize(face_normal));
	vec2 p = n.y > 0.65 ? point.xz : (n.z > n.x ? point.xy : point.zy);
	vec2 uv = p * (surface_kind == 1 || surface_kind == 2 ? vec2(0.9,0.8) : vec2(1.1));
	vec3 sample_color = texture(surface_tex, uv).rgb;
	float value = dot(sample_color,vec3(0.2126,0.7152,0.0722));
	if(surface_kind == 1 || surface_kind == 2){
		float grain = clamp(value / 0.125,0.35,2.3);
		ALBEDO = tint.rgb * mix(1.0,grain,0.38);
		if(surface_kind == 2 && n.y > 0.65){
			float board = floor(p.x * 3.5);
			float seam = smoothstep(0.0,0.012,min(fract(p.x*3.5),1.0-fract(p.x*3.5)));
			float join = smoothstep(0.0,0.006,min(fract(p.y*0.7+board*0.37),1.0-fract(p.y*0.7+board*0.37)));
			ALBEDO *= 0.72 + 0.28*min(seam,join);
		}
		ROUGHNESS = (surface_kind == 1 ? 0.36 : 0.62)+value*0.18;
		SPECULAR = 0.5;
	}else{
		float grain = clamp(value/(surface_kind == 0 ? 0.53 : 0.18),0.45,1.6);
		ALBEDO = tint.rgb * mix(1.0,grain,0.28);
		if(wallpaper>0){
			vec2 wall_uv = n.z > n.x ? world_point.xy : world_point.zy;
			float stripe = abs(fract(wall_uv.x*4.0)-0.5);
			float band = 1.0-smoothstep(0.19,0.23,stripe);
			ALBEDO *= 0.90+band*0.19;
			if(wallpaper>=2){
				vec2 tile=abs(fract(wall_uv*vec2(3.1,3.5))-0.5);
				float diamond=1.0-smoothstep(0.018,0.045,abs(tile.x+tile.y*0.8-0.34));
				ALBEDO*=1.0+diamond*0.13;
			}
		}
		ROUGHNESS = surface_kind == 4 ? 0.62 : 0.88;
		SPECULAR = surface_kind == 4 ? 0.42 : 0.18;
	}
	// Fine bump is derived in the shader; no extra geometry is needed.
	vec2 step_uv = vec2(1.0) / vec2(textureSize(surface_tex,0));
	float right = dot(texture(surface_tex,uv+vec2(step_uv.x,0.0)).rgb,vec3(0.2126,0.7152,0.0722));
	float up = dot(texture(surface_tex,uv+vec2(0.0,step_uv.y)).rgb,vec3(0.2126,0.7152,0.0722));
	vec3 bump = normalize(vec3((value-right)*0.7,(value-up)*0.7,1.0));
	NORMAL_MAP = bump*0.5+0.5;
}
