import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
// Rive는 Windows에서 segfault 유발 → POC에서는 fallback 렌더러 사용
// import 'package:rive/rive.dart' as rive;

/// Rive 유닛 렌더러 (POC-1: Rive + Flame 통합 검증)
/// 현재 Fallback 원형 렌더링 모드 (Rive 네이티브 플러그인 Windows 호환 문제)
class RiveUnitRenderer extends PositionComponent {
  RiveUnitRenderer({
    super.position,
    super.size,
    this.unitColor = const Color(0xFF4488FF),
    this.label = '',
  });

  final Color unitColor;
  final String label;

  // Rive 비활성화 (Windows segfault 방지)
  final bool _riveLoaded = false;

  // Animation state
  int _animState = 0; // 0:idle, 1:walk, 2:attack, 3:hurt, 4:dead
  double _animTimer = 0;
  double _pulsePhase = 0;

  static const stateNames = ['IDLE', 'WALK', 'ATK', 'HURT', 'DEAD'];

  bool get riveLoaded => _riveLoaded;
  int get animState => _animState;

  /// Rive 파일 로드 시도 (현재 비활성화)
  Future<bool> tryLoadRive(String assetPath) async {
    // Rive 네이티브 플러그인이 Windows에서 segfault → fallback 모드 강제
    return false;
  }

  /// 애니메이션 상태 설정 (0:idle, 1:walk, 2:attack, 3:hurt, 4:dead)
  void setAnimState(int stateIndex) {
    _animState = stateIndex.clamp(0, 4);
    _animTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
    _pulsePhase += dt * 3; // pulse speed
  }

  @override
  void render(Canvas canvas) {
    _renderFallback(canvas);
    super.render(canvas);
  }

  void _renderFallback(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final radius = min(size.x, size.y) / 2 - 2;

    // Dead state
    if (_animState == 4) {
      final paint = Paint()
        ..color = unitColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius * 0.6, paint);
      _drawLabel(canvas, cx, cy, 'DEAD');
      return;
    }

    // State-dependent effects
    final pulse = sin(_pulsePhase) * 0.1;
    final effectiveRadius = radius * (1.0 + pulse);

    // Body circle
    final bodyPaint = Paint()
      ..color = _getStateColor()
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), effectiveRadius, bodyPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = unitColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), effectiveRadius, outlinePaint);

    // Attack flash
    if (_animState == 2 && _animTimer < 0.3) {
      final flashAlpha = (1.0 - _animTimer / 0.3);
      final flashPaint = Paint()
        ..color = const Color(0xFFFFFF00).withValues(alpha: flashAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), effectiveRadius * 1.3, flashPaint);
    }

    // Hurt flash
    if (_animState == 3 && _animTimer < 0.2) {
      final flashAlpha = (1.0 - _animTimer / 0.2);
      final flashPaint = Paint()
        ..color = const Color(0xFFFF0000).withValues(alpha: flashAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), effectiveRadius, flashPaint);
    }

    // Walk indicator (rotating dots)
    if (_animState == 1) {
      final dotPaint = Paint()..color = const Color(0xFFFFFFFF);
      for (int i = 0; i < 3; i++) {
        final angle = _pulsePhase * 2 + i * (2 * pi / 3);
        final dx = cx + cos(angle) * (effectiveRadius + 4);
        final dy = cy + sin(angle) * (effectiveRadius + 4);
        canvas.drawCircle(Offset(dx, dy), 2, dotPaint);
      }
    }

    _drawLabel(canvas, cx, cy - radius - 10, '${label.isNotEmpty ? label : ''} ${stateNames[_animState]}');
  }

  Color _getStateColor() {
    return switch (_animState) {
      0 => unitColor.withValues(alpha: 0.7), // idle
      1 => unitColor.withValues(alpha: 0.85), // walk
      2 => unitColor.withValues(alpha: 1.0), // attack
      3 => const Color(0xFFFF4444).withValues(alpha: 0.8), // hurt
      4 => unitColor.withValues(alpha: 0.3), // dead
      _ => unitColor,
    };
  }

  void _drawLabel(Canvas canvas, double x, double y, String text) {
    final paragraphBuilder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 10,
    ))
      ..pushStyle(TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(text);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ParagraphConstraints(width: 80));
    canvas.drawParagraph(paragraph, Offset(x - 40, y));
  }
}
