import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';

/// 데미지 팝업 컴포넌트
class DamagePopup extends TextComponent {
  DamagePopup({
    required int damage,
    required Vector2 popupPosition,
    bool isCritical = false,
    bool isMiss = false,
  }) : super(
          text: isMiss ? 'MISS' : '${isCritical ? "CRIT " : ""}$damage',
          position: popupPosition,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: isMiss
                  ? const Color(0xFF888888)
                  : isCritical
                      ? const Color(0xFFFFFF00)
                      : const Color(0xFFFFFFFF),
              fontSize: isCritical ? 20 : 16,
              fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 위로 떠오르며 사라지는 효과
    add(MoveEffect.by(
      Vector2(0, -40),
      EffectController(duration: 0.8),
    ));
    add(RemoveEffect(delay: 0.8));
  }
}
