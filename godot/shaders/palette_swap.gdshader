shader_type canvas_item;

uniform sampler2D palette_texture : filter_nearest;
uniform int palette_index : hint_range(0, 7) = 0;
uniform int palette_count : hint_range(1, 8) = 8;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);

    // 밝기 기반 16색 인덱스 계산 (grayscale)
    float brightness = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    float index = floor(brightness * 15.0 + 0.5);

    // 팔레트 UV 계산
    float palette_u = (index + 0.5) / 16.0;
    float palette_v = (float(palette_index) + 0.5) / float(palette_count);

    // 팔레트에서 색상 조회
    vec4 new_color = texture(palette_texture, vec2(palette_u, palette_v));

    COLOR = vec4(new_color.rgb, pixel.a);
}
