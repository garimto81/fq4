import 'dart:ui';
import 'package:flame/components.dart';

/// 유닛 시각적 렌더링 (임시: 색상 사각형 + HP 바)
/// 추후 Rive 애니메이션으로 교체
mixin UnitRenderer on PositionComponent {
  Color get unitColor;
  double get hpRatio;
  bool get isDead;
  String get unitName;
  bool get isHighlighted => false;

  @override
  void render(Canvas canvas) {
    if (isDead) return;

    // 유닛 본체 (사각형)
    final bodyPaint = Paint()..color = unitColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // 하이라이트 테두리
    if (isHighlighted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(4),
        ),
        Paint()
          ..color = const Color(0xFFFFFF00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // HP 바 배경
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x, 4),
      Paint()..color = const Color(0xFF333333),
    );

    // HP 바
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF00CC00)
        : hpRatio > 0.25
            ? const Color(0xFFCCCC00)
            : const Color(0xFFCC0000);
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x * hpRatio, 4),
      Paint()..color = hpColor,
    );

    super.render(canvas);
  }
}
