// 환경 시스템 (Godot environment_system.gd에서 이식)

import '../../core/constants/status_effect_constants.dart';
import 'status_effect_system.dart';

/// 지형 존 정의
class TerrainZone {
  final String id;
  final TerrainType terrainType;
  final double x;
  final double y;
  final double width;
  final double height;

  const TerrainZone({
    required this.id,
    required this.terrainType,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// 좌표가 이 존 안에 있는지 확인
  bool contains(double px, double py) {
    return px >= x && px < x + width && py >= y && py < y + height;
  }
}

/// 환경 시스템 (순수 Dart 클래스)
class EnvironmentSystem {
  // 지형 존 목록
  final List<TerrainZone> _terrainZones = [];

  // 유닛별 현재 지형 상태: unitId -> TerrainType
  final Map<int, TerrainType> _unitTerrainState = {};

  // 상태이상 시스템 참조 (지형 효과 적용용)
  StatusEffectSystem? statusEffectSystem;

  /// 지형 존 등록
  void registerTerrainZone(TerrainZone zone) {
    _terrainZones.add(zone);
  }

  /// 지형 존 제거
  void unregisterTerrainZone(String id) {
    _terrainZones.removeWhere((zone) => zone.id == id);
  }

  /// 모든 지형 존 제거
  void clearTerrainZones() {
    _terrainZones.clear();
  }

  /// 유닛 위치의 지형 확인 및 상태이상 적용
  TerrainType? checkUnitTerrain(int unitId, double x, double y) {
    // 현재 위치의 지형 찾기 (여러 존이 겹치면 마지막 등록된 것 사용)
    TerrainType? currentTerrain;
    for (final zone in _terrainZones) {
      if (zone.contains(x, y)) {
        currentTerrain = zone.terrainType;
      }
    }

    // 지형이 없으면 NORMAL로 간주
    currentTerrain ??= TerrainType.normal;

    // 이전 지형과 다르면 상태 업데이트
    final previousTerrain = _unitTerrainState[unitId];
    if (previousTerrain != currentTerrain) {
      _unitTerrainState[unitId] = currentTerrain;

      // 새 지형에 상태이상이 있으면 적용
      if (currentTerrain.statusEffect != null) {
        statusEffectSystem?.applyEffect(unitId, currentTerrain.statusEffect!);
      }
    }

    return currentTerrain;
  }

  /// 유닛의 현재 지형 조회
  TerrainType getCurrentTerrain(int unitId) {
    return _unitTerrainState[unitId] ?? TerrainType.normal;
  }

  /// 속도 배율 계산
  double getSpeedModifier(int unitId) {
    final terrain = getCurrentTerrain(unitId);
    return terrain.speedMult;
  }

  /// 피로도 배율 계산
  double getFatigueMultiplier(int unitId) {
    final terrain = getCurrentTerrain(unitId);
    return terrain.fatigueMult;
  }

  /// 탐지 범위 배율 계산
  double getDetectionModifier(int unitId) {
    final terrain = getCurrentTerrain(unitId);
    return terrain.detectionMult;
  }

  /// 유닛 제거 (사망 시)
  void removeUnit(int unitId) {
    _unitTerrainState.remove(unitId);
  }

  /// 전체 초기화
  void reset() {
    _terrainZones.clear();
    _unitTerrainState.clear();
  }

  /// 등록된 지형 존 개수
  int get terrainZoneCount => _terrainZones.length;

  /// 등록된 지형 존 목록 (읽기 전용)
  List<TerrainZone> get terrainZones => List.unmodifiable(_terrainZones);
}
