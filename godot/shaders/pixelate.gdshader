shader_type canvas_item;

// 픽셀화 파라미터
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;
uniform bool apply_dithering = true;
uniform float dither_intensity : hint_range(0.0, 1.0) = 0.3;

// Bayer 디더링 매트릭스 4x4
const mat4 bayer_matrix = mat4(
    vec4(0.0, 8.0, 2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0, 1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

float get_bayer_value(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    return bayer_matrix[x][y];
}

void fragment() {
    // 픽셀 그리드 좌표 계산
    vec2 pixel_uv = floor(UV * vec2(1.0 / TEXTURE_PIXEL_SIZE) / pixel_size) * pixel_size;
    vec2 final_uv = pixel_uv * TEXTURE_PIXEL_SIZE;

    // 텍스처 샘플링
    vec4 col = texture(TEXTURE, final_uv);

    // 디더링 적용
    if (apply_dithering) {
        vec2 screen_pos = FRAGCOORD.xy;
        float bayer = get_bayer_value(screen_pos);
        col.rgb += (bayer - 0.5) * dither_intensity / 16.0;
    }

    COLOR = col;
}
