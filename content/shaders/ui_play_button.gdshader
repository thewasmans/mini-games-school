shader_type canvas_item;

uniform vec2 button_size = vec2(421.0, 90.0);

group_uniforms breathing;
uniform float breathe_amount : hint_range(0.0, 0.3) = 0.06;
uniform float breathe_speed : hint_range(0.0, 10.0) = 2.4;
uniform float wobble_angle_degrees : hint_range(0.0, 10.0) = 1.5;
uniform float wobble_speed : hint_range(0.0, 10.0) = 1.3;

group_uniforms shine;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float shine_width : hint_range(0.01, 0.5) = 0.1;
uniform float shine_slope : hint_range(-1.0, 1.0) = 0.4;
uniform float shine_interval : hint_range(0.5, 10.0) = 3.0;
uniform float shine_duration : hint_range(0.1, 3.0) = 0.7;

varying vec2 local_uv;

vec2 rotate(vec2 point, float angle) {
	float cosine = cos(angle);
	float sine = sin(angle);
	return vec2(cosine * point.x - sine * point.y, sine * point.x + cosine * point.y);
}

float shine(vec2 uv) {
	float progress = mod(TIME, shine_interval) / shine_duration;
	if (progress > 1.0) {
		return 0.0;
	}
	float band_position = mix(-shine_width - abs(shine_slope), 1.0 + shine_width + abs(shine_slope), progress);
	float distance_to_band = abs(uv.x + uv.y * shine_slope - band_position);
	return 1.0 - smoothstep(0.0, shine_width, distance_to_band);
}

void vertex() {
	local_uv = VERTEX / button_size;
	vec2 center = button_size * 0.5;
	float breathe_scale = 1.0 + breathe_amount * (0.5 + 0.5 * sin(TIME * breathe_speed));
	float wobble_angle = radians(wobble_angle_degrees) * sin(TIME * wobble_speed);
	VERTEX = center + rotate(VERTEX - center, wobble_angle) * breathe_scale;
}

void fragment() {
	COLOR.rgb += shine_color.rgb * shine_color.a * shine(local_uv) * COLOR.a;
	COLOR.rgb = min(COLOR.rgb, vec3(1.0));
}
