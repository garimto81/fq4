shader_type canvas_item;

// 외곽선 파라미터
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 10.0) = 1.5;
uniform bool use_palette_color = false;

void fragment() {
    // 현재 픽셀의 alpha 값
    float alpha = texture(TEXTURE, UV).a;

    // 외곽선 검출 (8방향)
    float outline = 0.0;
    vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_thickness;

    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            if (x == 0.0 && y == 0.0) continue;

            vec2 offset = vec2(x, y) * pixel_size;
            float neighbor_alpha = texture(TEXTURE, UV + offset).a;

            // 투명한 곳에서 불투명한 곳으로 전환되는 경계 검출
            if (alpha < 0.1 && neighbor_alpha > 0.1) {
                outline = 1.0;
                break;
            }
        }
        if (outline > 0.0) break;
    }

    // 최종 색상 결정
    vec4 tex_color = texture(TEXTURE, UV);

    if (outline > 0.0) {
        // 외곽선 색상
        if (use_palette_color) {
            // 인접한 픽셀의 색상을 어둡게 하여 외곽선으로 사용
            vec4 neighbor_color = vec4(0.0);
            float count = 0.0;

            for (float x = -1.0; x <= 1.0; x += 1.0) {
                for (float y = -1.0; y <= 1.0; y += 1.0) {
                    vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
                    vec4 sample_color = texture(TEXTURE, UV + offset);
                    if (sample_color.a > 0.1) {
                        neighbor_color += sample_color;
                        count += 1.0;
                    }
                }
            }

            if (count > 0.0) {
                neighbor_color /= count;
                neighbor_color.rgb *= 0.3; // 어둡게
                COLOR = neighbor_color;
            } else {
                COLOR = outline_color;
            }
        } else {
            COLOR = outline_color;
        }
    } else if (alpha > 0.1) {
        // 스프라이트 본체
        COLOR = tex_color;
    } else {
        // 투명
        COLOR = vec4(0.0);
    }
}
