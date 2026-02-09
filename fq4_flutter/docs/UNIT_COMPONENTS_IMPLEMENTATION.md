# Unit Components Implementation Summary

**Date**: 2026-02-08
**Phase**: Phase 1 - Unit Component Hierarchy
**Status**: ✅ Completed

## Overview

Flutter/Flame FQ4 프로젝트의 Unit 컴포넌트 계층 구현 완료. Godot 원본 클래스 계층을 1:1로 이식.

## Implemented Files

### 1. `lib/game/components/units/unit_component.dart` (155 lines)
기본 유닛 컴포넌트 (Godot `unit.gd` 이식)

**Features:**
- `UnitState` enum: `idle`, `moving`, `attacking`, `resting`, `dead`
- 기본 스탯: `maxHp`, `maxMp`, `attack`, `defense`, `speed`, `luck`
- 현재 상태: `currentHp`, `currentMp`, `fatigue`
- 이동: `velocity`, `moveTarget`, `moveTo()`
- 전투: `attackCooldown`, `tryAttack()`, `takeDamage()`
- 상태별 처리: `_processIdle()`, `_processMoving()`, `_processAttacking()`, `_processResting()`
- `toUnitStats()`: `CombatSystem` 연동용

**Key Methods:**
```dart
void takeDamage(int damage)
void heal(int amount)
bool consumeMp(int cost)
void die()
void moveTo(Vector2 target)
bool tryAttack()
UnitStats toUnitStats()
```

### 2. `lib/game/components/units/ai_unit_component.dart` (98 lines)
AI 자동 제어 유닛 (Godot `ai_unit.gd` 이식)

**Features:**
- `AIBrain` 통합: `Personality`, `Formation` 지원
- `isPlayerControlled`: true이면 AI 비활성화
- `squadId`: 부대 ID
- `_buildContext()`: `AIContext` 생성 (GameManager 참조)
- `_executeDecision()`: AI 결정 실행

**AI Decision Types:**
- `follow`, `chase`, `retreat`, `defend`: 이동
- `attack`: 공격
- `rest`: 휴식
- `heal`: 회복 (TODO)
- `scatter`: 랜덤 이동

### 3. `lib/game/components/units/player_unit_component.dart` (77 lines)
플레이어 직접 조작 유닛 (Godot `player_unit.gd` 이식)

**Features:**
- `KeyboardHandler` mixin: 키보드 입력 처리
- WASD / Arrow Keys: 이동
- Space: 공격
- `isPlayerControlled = true`: 자동 설정
- `isPlayerSide = true`: 아군

**Controls:**
- `W` / `↑`: 위로 이동
- `S` / `↓`: 아래로 이동
- `A` / `←`: 왼쪽으로 이동
- `D` / `→`: 오른쪽으로 이동
- `Space`: 공격

### 4. `lib/game/components/units/enemy_unit_component.dart` (58 lines)
적 유닛 (Godot `enemy_unit.gd` 이식)

**Features:**
- `expReward`, `goldReward`: 보상
- `isPlayerSide = false`: 적
- 간단한 AI: 가장 가까운 아군 추적
- `_aiTimer`: 0.3초 간격 AI tick
- `AIConstants.enemyDetectionRange`: 탐지 범위

**AI Logic:**
```dart
if (distance <= 40) {
  tryAttack();
} else {
  moveTo(target.position);
}
```

### 5. `lib/game/components/units/boss_unit_component.dart` (69 lines)
보스 유닛 (Godot `boss_unit.gd` 이식)

**Features:**
- `BossPhase` enum: `phase1`, `phase2`, `phase3`
- 멀티 페이즈: HP 66% / 33% 전환
- 광폭화: HP 20% 이하, 공격력 1.5배, 속도 1.3배
- 페이즈별 버프:
  - Phase 2: 방어력 1.2배
  - Phase 3: 공격력 1.3배

**Thresholds:**
- Phase 2: 66% HP
- Phase 3: 33% HP
- Enrage: 20% HP

### 6. `lib/game/components/units/units.dart` (14 lines)
Barrel export 파일

**Usage:**
```dart
import 'package:fq4_flutter/game/components/units/units.dart';
```

## Class Hierarchy

```
UnitComponent (CharacterBody2D equivalent)
├── AIUnitComponent
│   └── PlayerUnitComponent (KeyboardHandler mixin)
└── EnemyUnitComponent
    └── BossUnitComponent
```

## Dependencies

### Internal
- `lib/core/constants/ai_constants.dart`: `AIState`, `Personality`, `Formation`, `SquadCommand`, `AIConstants`
- `lib/core/constants/fatigue_constants.dart`: `FatigueConstants`, `FatigueLevel`
- `lib/game/systems/combat_system.dart`: `UnitStats`
- `lib/game/systems/fatigue_system.dart`: `FatigueSystem`
- `lib/game/ai/ai_brain.dart`: `AIBrain`, `AIContext`, `AIDecision`, `AIDecisionType`
- `lib/game/managers/game_manager.dart`: `GameManager`

### External
- `flame`: `^1.21.0`
  - `PositionComponent`
  - `HasGameReference`
  - `CollisionCallbacks`
  - `RectangleHitbox`
  - `KeyboardHandler`
- `flutter/services.dart`: `LogicalKeyboardKey`, `KeyEvent`

## Testing

### Test File
`test/game/components/units/unit_component_test.dart` (247 lines)

**Test Coverage:**
- `UnitComponent`: 초기화, 데미지, 사망, 회복, MP 소비, 변환
- `AIUnitComponent`: 초기화, 플레이어 제어
- `PlayerUnitComponent`: 초기화, isPlayerSide/isPlayerControlled
- `EnemyUnitComponent`: 초기화, isPlayerSide, 보상
- `BossUnitComponent`: 페이즈 전환, 광폭화

**Run Tests:**
```bash
flutter test test/game/components/units/unit_component_test.dart
```

## Integration Points

### GameManager
- `findParent<GameManager>()`: 부모 컴포넌트 검색
- `gm.playerUnits`: 아군 유닛 리스트
- `gm.enemyUnits`: 적 유닛 리스트
- `gm.controlledUnit`: 현재 조작 중인 유닛

### CombatSystem
- `unit.toUnitStats()`: 전투 계산용 스탯 변환
- `CombatSystem.calculateDamage(attacker, defender)`: 데미지 계산

### FatigueSystem
- `_fatigueSystem.canAct(fatigue)`: 행동 가능 여부
- `_fatigueSystem.getSpeedMultiplier(fatigue)`: 속도 배율
- `_fatigueSystem.addMoveFatigue(fatigue, distance)`: 이동 피로도
- `_fatigueSystem.addAttackFatigue(fatigue)`: 공격 피로도
- `_fatigueSystem.recover(fatigue, dt, isResting)`: 피로도 회복

### AIBrain
- `aiBrain.update(dt, context)`: AI 결정 생성
- `AIContext`: HP 비율, 피로도, 리더 위치, 적 위치, 거리 정보

## Gocha-Kyara System Support

**핵심 메커니즘:**
- 플레이어는 1명만 직접 조작 (`isPlayerControlled = true`)
- 나머지 부대원은 AI가 자동 제어 (`isPlayerControlled = false`)
- `←→` / `↑↓`: 조작 유닛 전환 (GameManager에서 처리)

**구현 상태:**
- ✅ 유닛 클래스 계층
- ✅ AI/플레이어 제어 전환 플래그
- ⏳ 부대 관리 (`GameManager`)
- ⏳ 유닛 전환 입력 (`GameManager`)

## Performance Considerations

**Object Pooling:**
- 현재: 각 유닛은 개별 `Component` 인스턴스
- 향후: 100 유닛 목표 시 `PoolManager` 연동 필요

**Spatial Hash:**
- `GameManager`의 `SpatialHash` 사용
- `findParent<GameManager>()` 경유로 공간 쿼리

**Update Optimization:**
- `isDead` 체크로 사망 유닛 업데이트 스킵
- AI tick 간격: 0.3초 (`AIConstants.enemyTickInterval`)

## Known Issues

None. 모든 import 경로 검증 완료.

## Next Steps

1. **GameManager 통합**
   - `registerUnit()` / `unregisterUnit()`
   - `squadManager` 연동
   - 조작 유닛 전환 (`←→`, `↑↓`)

2. **UI 연동**
   - HP/MP 바
   - 피로도 표시
   - 유닛 선택 표시

3. **렌더링**
   - Rive 애니메이션 연동
   - 방향별 스프라이트
   - 이펙트 (데미지 팝업, HitFlash)

4. **전투 시스템 연동**
   - `CombatSystem.resolveAttack(attacker, defender)`
   - 공격 범위 체크
   - 충돌 감지

5. **테스트 씬**
   - 유닛 생성 테스트
   - AI 동작 테스트
   - 조작 전환 테스트

## Files Created

```
lib/game/components/units/
├── unit_component.dart          (155 lines)
├── ai_unit_component.dart       (98 lines)
├── player_unit_component.dart   (77 lines)
├── enemy_unit_component.dart    (58 lines)
├── boss_unit_component.dart     (69 lines)
└── units.dart                   (14 lines)

test/game/components/units/
└── unit_component_test.dart     (247 lines)

docs/
└── UNIT_COMPONENTS_IMPLEMENTATION.md (this file)

Total: 718 lines
```

## References

- Godot 원본: `/mnt/c/claude/Fq4/fq4_flutter/godot/scripts/units/`
- PRD: `docs/PRD-0001-first-queen-4-remake.md`
- GDD: `docs/FQ4_INTEGRATED_GDD.md`
- CLAUDE.md: `CLAUDE.md` (Gocha-Kyara 시스템 설명)
