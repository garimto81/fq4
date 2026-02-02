shader_type canvas_item;

// CRT 효과 파라미터
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scan_line_count : hint_range(100.0, 1000.0) = 400.0;
uniform float curvature : hint_range(0.0, 0.1) = 0.03;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float flicker_speed : hint_range(0.0, 10.0) = 2.0;

// 랜덤 노이즈 생성
float random(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// CRT 곡률 왜곡
vec2 curve_uv(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(curvature, curvature);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void fragment() {
    // UV 곡률 적용
    vec2 curved_uv = curve_uv(UV);

    // 화면 밖 체크 - else로 처리하여 return 회피
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // Chromatic aberration (색수차)
        float r = texture(TEXTURE, curved_uv + vec2(chromatic_aberration, 0.0)).r;
        float g = texture(TEXTURE, curved_uv).g;
        float b = texture(TEXTURE, curved_uv - vec2(chromatic_aberration, 0.0)).b;
        vec3 col = vec3(r, g, b);

        // 주사선 효과
        float scan_line = sin(curved_uv.y * scan_line_count) * scan_line_intensity;
        col -= scan_line;

        // 비네팅 효과
        vec2 center = curved_uv * 2.0 - 1.0;
        float vignette = 1.0 - dot(center, center) * vignette_intensity;
        col *= vignette;

        // 노이즈 효과
        float noise = random(curved_uv + vec2(TIME * 0.1, TIME * 0.2)) * noise_intensity;
        col += noise;

        // 깜빡임 효과 (미세)
        float flicker = sin(TIME * flicker_speed) * 0.02 + 0.98;
        col *= flicker;

        COLOR = vec4(col, 1.0);
    }
}
