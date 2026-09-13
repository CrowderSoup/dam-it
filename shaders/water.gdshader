shader_type canvas_item;
// Animated water: a vertical gradient plus two crossing sine waves whose
// product makes a soft, moving sparkle band - cheap to compute and reads
// as "flowing water" without needing any texture.

uniform vec4 shallow_color : source_color = vec4(0.4314, 0.7765, 0.8510, 1.0);
uniform vec4 deep_color : source_color = vec4(0.2275, 0.5608, 0.6902, 1.0);
uniform float wave_speed = 0.6;
uniform float wave_scale = 18.0;
uniform float sparkle_strength = 0.35;

void fragment() {
	vec3 base = mix(shallow_color.rgb, deep_color.rgb, UV.y);
	float wave_a = sin(UV.x * wave_scale + TIME * wave_speed) * 0.5 + 0.5;
	float wave_b = sin(UV.x * wave_scale * 1.7 - TIME * wave_speed * 1.3 + 1.5) * 0.5 + 0.5;
	float sparkle = pow(wave_a * wave_b, 4.0) * sparkle_strength;
	COLOR = vec4(base + sparkle, mix(shallow_color.a, deep_color.a, UV.y));
}
