import 'package:flame/components.dart';

/// 게임 카메라 컨트롤러
/// Flame의 기본 CameraComponent를 사용하되 follow 대상을 관리
class GameCameraController extends Component with HasGameReference {
  GameCameraController({
    Vector2? mapSize,
    this.followSpeed = 5.0,
  }) : mapSize = mapSize ?? Vector2(2560, 1600);

  final Vector2 mapSize;
  final double followSpeed;
  PositionComponent? followTarget;

  void setFollowTarget(PositionComponent target) {
    followTarget = target;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (followTarget == null) return;

    final camera = game.camera;
    final viewSize = camera.viewfinder.visibleGameSize;
    if (viewSize == null) return;

    // 현재 카메라 위치
    final current = camera.viewfinder.position;

    // 목표 위치 (대상 중심)
    var targetX = followTarget!.position.x;
    var targetY = followTarget!.position.y;

    // 맵 경계 제한
    final halfW = viewSize.x / 2;
    final halfH = viewSize.y / 2;
    targetX = targetX.clamp(halfW, mapSize.x - halfW);
    targetY = targetY.clamp(halfH, mapSize.y - halfH);

    // 부드러운 추적
    final lerpFactor = (followSpeed * dt).clamp(0.0, 1.0);
    camera.viewfinder.position = Vector2(
      current.x + (targetX - current.x) * lerpFactor,
      current.y + (targetY - current.y) * lerpFactor,
    );
  }
}
