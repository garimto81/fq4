import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/text.dart';

/// 전투 HUD 컴포넌트
class BattleHud extends PositionComponent with HasGameReference {
  // 표시 데이터
  String unitName = '';
  int currentHp = 0;
  int maxHp = 0;
  int currentMp = 0;
  int maxMp = 0;
  double fatigue = 0;
  int squadId = 0;
  int unitIndex = 0;
  int squadSize = 0;
  String gameStateText = '';

  late final TextComponent _nameText;
  late final TextComponent _hpText;
  late final TextComponent _mpText;
  late final TextComponent _fatigueText;
  late final TextComponent _squadText;
  late final TextComponent _stateText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // HUD를 화면 좌상단에 고정 (카메라 무시)
    final textStyle = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 14,
        fontFamily: 'monospace',
      ),
    );

    _nameText = TextComponent(textRenderer: textStyle, position: Vector2(10, 10));
    _hpText = TextComponent(textRenderer: textStyle, position: Vector2(10, 28));
    _mpText = TextComponent(textRenderer: textStyle, position: Vector2(10, 46));
    _fatigueText = TextComponent(textRenderer: textStyle, position: Vector2(10, 64));
    _squadText = TextComponent(textRenderer: textStyle, position: Vector2(10, 82));
    _stateText = TextComponent(textRenderer: textStyle, position: Vector2(10, 100));

    addAll([_nameText, _hpText, _mpText, _fatigueText, _squadText, _stateText]);
  }

  /// HUD 데이터 갱신
  void updateData({
    required String name,
    required int hp,
    required int hpMax,
    required int mp,
    required int mpMax,
    required double fatigueValue,
    required int squad,
    required int index,
    required int total,
    required String state,
  }) {
    unitName = name;
    currentHp = hp;
    maxHp = hpMax;
    currentMp = mp;
    maxMp = mpMax;
    fatigue = fatigueValue;
    squadId = squad;
    unitIndex = index;
    squadSize = total;
    gameStateText = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _nameText.text = '[$unitName] Lv.$unitIndex';
    _hpText.text = 'HP: $currentHp/$maxHp';
    _mpText.text = 'MP: $currentMp/$maxMp';
    _fatigueText.text = 'Fatigue: ${fatigue.toStringAsFixed(0)}%';
    _squadText.text = 'Squad $squadId [${unitIndex + 1}/$squadSize]';
    _stateText.text = gameStateText;
  }

  @override
  void render(Canvas canvas) {
    // HUD 배경 박스
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, 200, 116),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xAA000000),
    );
    super.render(canvas);
  }
}
