import 'dart:ui';
import 'package:flame/components.dart';

/// 미니맵 컴포넌트
class Minimap extends PositionComponent with HasGameReference {
  Minimap({
    Vector2? mapWorldSize,
    Vector2? minimapSize,
  })  : mapWorldSize = mapWorldSize ?? Vector2(2560, 1600),
        minimapSize = minimapSize ?? Vector2(150, 94);

  final Vector2 mapWorldSize;
  final Vector2 minimapSize;

  // 유닛 위치 데이터
  List<({double x, double y, bool isPlayer, bool isControlled})> unitPositions = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = minimapSize;
  }

  void updatePositions(List<({double x, double y, bool isPlayer, bool isControlled})> positions) {
    unitPositions = positions;
  }

  @override
  void render(Canvas canvas) {
    // 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, minimapSize.x, minimapSize.y),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xAA000000),
    );

    // 테두리
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, minimapSize.x, minimapSize.y),
        const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0xFF888888)
        ..style = PaintingStyle.stroke,
    );

    // 유닛 점
    for (final unit in unitPositions) {
      final mx = (unit.x / mapWorldSize.x) * minimapSize.x;
      final my = (unit.y / mapWorldSize.y) * minimapSize.y;

      final color = unit.isControlled
          ? const Color(0xFFFFFFFF) // 현재 조작 유닛: 흰색
          : unit.isPlayer
              ? const Color(0xFF4488FF) // 아군: 파랑
              : const Color(0xFFFF4444); // 적: 빨강

      canvas.drawCircle(
        Offset(mx, my),
        unit.isControlled ? 3 : 2,
        Paint()..color = color,
      );
    }
  }
}
