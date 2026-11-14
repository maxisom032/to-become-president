shader_type spatial;

uniform vec4 tint : source_color = vec4(0.5, 0.4, 0.3, 1.0);
uniform int finish = 0;
uniform int wallpaper = 0;
varying vec3 local_point;
varying vec3 local_normal;
varying vec3 world_point;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), u.x), u.y);
}

void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = local_point.xy;
	if (abs(local_normal.y) > 0.5) {
		p = local_point.xz;
	} else if (abs(local_normal.x) > 0.5) {
		p = local_point.zy;
	}
	float detail = grain(p * 8.0) * 0.12 + grain(p * 75.0) * 0.08;
	if (finish == 1 || finish == 3 || finish == 4) {
		float curl = grain(p * vec2(4.5, 1.3)) * 4.5 + grain(p * 11.0) * 0.35;
		float rings = sin(p.x * 63.0 + curl) * 0.044;
		detail += rings + grain(p * vec2(115.0, 2.3)) * 0.13;
		if (finish == 4) {
			float oak = sin(p.x * 38.0 + grain(p * vec2(3.1, 0.8)) * 5.0);
			detail += oak * 0.057 + grain(p * vec2(14.0, 1.4)) * 0.18;
		}
		if (finish == 3 && abs(local_normal.y) > 0.5) {
			float board = floor(p.x * 5.0);
			float seam = smoothstep(0.0, 0.024, abs(fract(p.x * 5.0) - 0.5));
			float join = smoothstep(0.0, 0.011, abs(fract(p.y * 0.56 + hash(vec2(board, 6.0))) - 0.5));
			detail += hash(vec2(board, 4.0)) * 0.19 - (1.0 - min(seam, join)) * 0.31;
		}
	}
	vec3 color = tint.rgb * (0.86 + detail);
	if (finish == 2 && wallpaper > 0) {
		vec2 wall_uv = abs(local_normal.z) > 0.5 ? world_point.xy : world_point.zy;
		float stripe = abs(fract(wall_uv.x * 5.0) - 0.5);
		if (wallpaper == 1) {
			float band = 1.0 - smoothstep(0.20, 0.24, stripe);
			float thread = 1.0 - smoothstep(0.035, 0.06, abs(stripe - 0.24));
			color *= 0.92 + band * 0.17 + thread * 0.10;
		} else {
			vec2 repeat_uv = wall_uv * vec2(3.9, 4.2);
			repeat_uv.y += mod(floor(repeat_uv.x), 2.0) * 0.5;
			vec2 tile = abs(fract(repeat_uv) - 0.5);
			float rhombus = tile.x + tile.y * 0.83;
			float contour = 1.0 - smoothstep(0.013, 0.047, abs(rhombus - 0.34));
			float bead = 1.0 - smoothstep(0.05, 0.11, rhombus);
			float decoration = wallpaper == 3 ? 0.25 : 0.12;
			color *= 0.95 + decoration * (contour + bead * 0.65);
			if (wallpaper == 3) {
				color += vec3(0.037, 0.020, 0.007) * contour;
			}
		}
	}
	if (finish == 2 && local_normal.z > 0.5) {
		vec2 light = vec2(world_point.x + world_point.y * 0.47, world_point.y - world_point.x * 0.16);
		vec2 falloff = abs(light - vec2(-1.08, 2.77));
		float window = (1.0 - smoothstep(0.68, 0.77, falloff.x)) * (1.0 - smoothstep(0.41, 0.50, falloff.y));
		vec2 bars = abs(fract(light * vec2(3.25, 2.6)) - 0.5);
		float panes = smoothstep(0.053, 0.113, min(bars.x, bars.y));
		EMISSION = vec3(0.14, 0.25, 0.28) * window * panes * 0.58;
	}
	ALBEDO = color;
	ROUGHNESS = finish == 4 ? 0.49 : (finish == 1 || finish == 3 ? 0.64 : 0.91);
}
