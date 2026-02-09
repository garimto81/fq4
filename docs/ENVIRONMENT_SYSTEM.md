# EnvironmentSystem 구현 문서

**Phase 6 Task 6.2: 환경 효과 시스템**

## 개요

지형 타입에 따른 상태 이상 및 능력치 디버프를 관리하는 시스템.

## 구현 파일

| 파일 | 역할 |
|------|------|
| `scripts/systems/environment_system.gd` | 환경 효과 시스템 메인 클래스 |
| `scripts/systems/status_effect_database.gd` | 상태이상 프리셋 생성 헬퍼 |
| `scenes/test/environment_test.tscn` | 환경 시스템 테스트 씬 |
| `scripts/test/test_environment_system.gd` | 테스트 스크립트 |

## 지형 타입 (TerrainType)

| 타입 | 효과 | 지속 방식 |
|------|------|----------|
| `NORMAL` | 효과 없음 | - |
| `WATER` | 이동속도 -30% | 지형 디버프 |
| `COLD` | 피로도 누적 +50% | 지형 디버프 |
| `DARK` | 감지 범위 -50% | 지형 디버프 |
| `POISON` | 독 상태이상 (5 dmg/sec) | 상태이상 시스템 |
| `FIRE` | 화상 상태이상 (8 dmg/sec) | 상태이상 시스템 |

## 지형 디버프 vs 상태이상

### 지형 디버프 (Terrain Debuff)
- **적용 방식:** Area2D 진입 시 즉시 적용
- **해제 방식:** Area2D 이탈 시 즉시 해제
- **대상:** WATER, COLD, DARK
- **관리:** EnvironmentSystem.terrain_debuffs Dictionary

### 상태이상 (Status Effect)
- **적용 방식:** Area2D 진입 시 StatusEffectSystem에 등록
- **해제 방식:** 지속 시간 종료 시 자동 해제 (지형 이탈과 무관)
- **대상:** POISON, FIRE
- **관리:** StatusEffectSystem.active_effects Dictionary

## API

### 초기화

```gdscript
var environment_system = $EnvironmentSystem
var status_effect_system = $StatusEffectSystem

environment_system.init(status_effect_system)
```

### 지형 영역 등록

```gdscript
var water_zone: Area2D = $WaterZone

# 기본 수치 사용
environment_system.register_terrain_zone(water_zone, EnvironmentSystem.TerrainType.WATER)

# 커스텀 수치 사용
environment_system.register_terrain_zone(
    water_zone,
    EnvironmentSystem.TerrainType.WATER,
    {"speed_modifier": 0.5}  # 속도 50% (더 느리게)
)
```

### 능력치 배율 조회

```gdscript
var unit = $Player

# 이동속도 배율 (물 지형)
var speed_mod = environment_system.get_speed_modifier(unit)
unit.move_speed = base_speed * speed_mod

# 피로도 배율 (한랭 지형)
var fatigue_mult = environment_system.get_fatigue_multiplier(unit)
fatigue_system.accumulate_fatigue(unit, base_fatigue * fatigue_mult)

# 감지 범위 배율 (어둠 지형)
var detection_mod = environment_system.get_detection_modifier(unit)
detection_range = base_range * detection_mod
```

### 시그널

```gdscript
environment_system.terrain_entered.connect(_on_terrain_entered)
environment_system.terrain_exited.connect(_on_terrain_exited)

func _on_terrain_entered(unit: Node, terrain_type: EnvironmentSystem.TerrainType):
    print("Unit entered terrain: ", EnvironmentSystem.TerrainType.keys()[terrain_type])

func _on_terrain_exited(unit: Node, terrain_type: EnvironmentSystem.TerrainType):
    print("Unit exited terrain: ", EnvironmentSystem.TerrainType.keys()[terrain_type])
```

## StatusEffectDatabase

사전 정의된 상태이상 효과를 생성하는 헬퍼 클래스.

### 사용 가능한 효과

| 효과 ID | 표시 이름 | 효과 타입 | 지속 시간 | 설명 |
|---------|----------|----------|----------|------|
| `"poison"` | 독 | POISON | 10초 | 1초마다 5 독 피해 |
| `"burn"` | 화상 | BURN | 8초 | 1초마다 8 화염 피해 |
| `"stun"` | 기절 | STUN | 3초 | 이동 및 공격 불가 |
| `"slow"` | 둔화 | SLOW | 5초 | 이동속도 50% 감소 |
| `"freeze"` | 빙결 | FREEZE | 4초 | 이동 및 행동 불가 |
| `"blind"` | 실명 | BLIND | 6초 | 감지 범위 80% 감소 |

### 사용 예시

```gdscript
# 독 상태이상 생성 및 적용
var poison_effect = StatusEffectDatabase.create_effect("poison")
status_effect_system.apply_effect(unit, poison_effect)

# 사용 가능한 효과 목록 조회
var all_effects = StatusEffectDatabase.get_all_effect_ids()
print(all_effects)  # ["poison", "burn", "stun", "slow", "freeze", "blind"]

# 카테고리별 조회
var debuffs = StatusEffectDatabase.get_debuff_ids()
var dot_effects = StatusEffectDatabase.get_damage_over_time_ids()
var cc_effects = StatusEffectDatabase.get_crowd_control_ids()
```

## 테스트 방법

### 1. 에디터에서 실행

```powershell
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/environment_test.tscn
```

### 2. 조작법

- **WASD:** 테스트 유닛 이동
- **I:** 디버그 정보 출력
- **ESC:** 종료

### 3. 확인 사항

- [ ] 물 지형(파란색) 진입 시 속도 감소
- [ ] 한랭 지형(하늘색) 진입 시 피로도 배율 증가
- [ ] 어둠 지형(회색) 진입 시 감지 범위 감소
- [ ] 독 지형(연두색) 진입 시 독 상태이상 적용
- [ ] 화염 지형(주황색) 진입 시 화상 상태이상 적용
- [ ] 지형 이탈 시 디버프 제거 (상태이상 제외)

## 통합 예시 (실제 게임)

```gdscript
# 맵 초기화 시
func _ready():
    # 환경 시스템 초기화
    var env_system = $EnvironmentSystem
    var status_system = $StatusEffectSystem
    env_system.init(status_system)

    # 맵의 모든 지형 영역 등록
    for zone in get_tree().get_nodes_in_group("terrain_zones"):
        var terrain_type = zone.terrain_type  # Area2D의 커스텀 프로퍼티
        env_system.register_terrain_zone(zone, terrain_type)

# 유닛 이동 시 속도 적용
func move_unit(unit, direction):
    var base_speed = unit.base_move_speed
    var speed_modifier = env_system.get_speed_modifier(unit)
    var fatigue_penalty = fatigue_system.get_speed_penalty(unit)

    var final_speed = base_speed * speed_modifier * fatigue_penalty
    unit.velocity = direction * final_speed
    unit.move_and_slide()

# AI 유닛의 감지 범위 적용
func update_detection_range(ai_unit):
    var base_range = ai_unit.base_detection_range
    var terrain_modifier = env_system.get_detection_modifier(ai_unit)

    ai_unit.detection_area.scale = Vector2.ONE * terrain_modifier
```

## 기술 세부사항

### 데이터 구조

```gdscript
# 지형 영역 저장
terrain_zones: Array[Dictionary] = [
    {
        "area": Area2D,
        "type": TerrainType,
        "modifier": Dictionary
    }
]

# 지형 디버프 추적
terrain_debuffs: Dictionary = {
    unit_id: {
        "water_slow": {"speed_modifier": 0.7},
        "cold_fatigue": {"fatigue_multiplier": 1.5},
        "darkness": {"detection_modifier": 0.5}
    }
}
```

### 시그널 흐름

```
Area2D.body_entered
    ↓
EnvironmentSystem._on_body_entered
    ↓
    ├─ WATER/COLD/DARK → terrain_debuffs에 추가
    ├─ POISON/FIRE → StatusEffectSystem.apply_effect()
    └─ terrain_entered 시그널 발생
```

## 성능 고려사항

- **메모리:** 유닛당 최대 3개의 지형 디버프 Dictionary (WATER, COLD, DARK)
- **CPU:** Area2D body_entered/exited 시그널만 처리, _process 호출 없음
- **확장성:** 최대 100개 지형 영역, 1000개 유닛까지 테스트 필요

## 향후 확장 계획

1. **추가 지형 타입**
   - `LAVA`: 지속 화상 + 이동속도 감소
   - `ICE`: 미끄러짐 효과 (관성 증가)
   - `WIND`: 특정 방향으로 밀림

2. **지형 조합 효과**
   - WATER + COLD = 빙결 (FREEZE 자동 적용)
   - FIRE + POISON = 폭발성 독가스

3. **날씨 시스템 연동**
   - 비 내릴 때 모든 WATER 효과 증폭
   - 눈 내릴 때 COLD 지형 범위 확장

## 문제 해결

### 디버프가 적용되지 않음

- [ ] EnvironmentSystem.init() 호출 확인
- [ ] Area2D가 "units" 그룹에 속한 유닛과 충돌하는지 확인
- [ ] register_terrain_zone() 호출 확인

### 지형 이탈 후에도 디버프 유지

- [ ] body_exited 시그널 연결 확인
- [ ] Area2D의 Collision Layer/Mask 설정 확인

### 상태이상이 적용되지 않음

- [ ] StatusEffectSystem 초기화 확인
- [ ] StatusEffectDatabase.create_effect() 반환값 확인
- [ ] status_effect_system.apply_effect() 호출 확인

## 참고 문서

- `docs/GAME_DESIGN_DOCUMENT.md` - 게임 설계 문서
- `scripts/systems/status_effect_system.gd` - 상태이상 시스템
- `scripts/resources/status_effect_data.gd` - 상태이상 데이터 리소스
