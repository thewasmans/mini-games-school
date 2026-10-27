shader_type canvas_item;

group_uniforms sparkles;
uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sparkle_size : hint_range(0.0, 0.3) = 0.07;
uniform float sparkle_speed : hint_range(0.0, 10.0) = 1.6;
uniform float sparkle_spin_speed : hint_range(0.0, 5.0) = 0.6;

const int SPARKLE_COUNT = 6;
const vec2 SPARKLE_POSITIONS[SPARKLE_COUNT] = vec2[](
	vec2(0.10, 0.22),
	vec2(0.88, 0.16),
	vec2(0.93, 0.62),
	vec2(0.14, 0.80),
	vec2(0.52, 0.10),
	vec2(0.66, 0.88)
);
const float SPARKLE_PHASES[SPARKLE_COUNT] = float[](0.0, 1.7, 3.1, 4.4, 2.3, 5.2);
const float SPARKLE_RAY_THICKNESS = 0.18;
const float SPARKLE_CORE_RADIUS = 0.35;

vec2 rotate(vec2 point, float angle) {
	float cosine = cos(angle);
	float sine = sin(angle);
	return vec2(cosine * point.x - sine * point.y, sine * point.x + cosine * point.y);
}

float four_point_star(vec2 point) {
	float horizontal_ray = max(0.0, 1.0 - abs(point.y) / (SPARKLE_RAY_THICKNESS * max(0.0, 1.0 - abs(point.x)) + 0.0001));
	float vertical_ray = max(0.0, 1.0 - abs(point.x) / (SPARKLE_RAY_THICKNESS * max(0.0, 1.0 - abs(point.y)) + 0.0001));
	float core = max(0.0, 1.0 - length(point) / SPARKLE_CORE_RADIUS);
	return max(max(horizontal_ray, vertical_ray), core);
}

float sparkles(vec2 uv, float aspect) {
	float total = 0.0;
	for (int index = 0; index < SPARKLE_COUNT; index++) {
		float phase = SPARKLE_PHASES[index];
		float twinkle = pow(max(0.0, sin(TIME * sparkle_speed + phase)), 3.0);
		float size = sparkle_size * twinkle;
		if (size <= 0.0001) {
			continue;
		}
		vec2 offset = (uv - SPARKLE_POSITIONS[index]) * vec2(aspect, 1.0);
		vec2 star_point = rotate(offset, TIME * sparkle_spin_speed + phase) / size;
		total += four_point_star(star_point);
	}
	return clamp(total, 0.0, 1.0);
}

void fragment() {
	float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	COLOR.rgb += sparkle_color.rgb * sparkle_color.a * sparkles(UV, aspect) * COLOR.a;
	COLOR.rgb = min(COLOR.rgb, vec3(1.0));
}
