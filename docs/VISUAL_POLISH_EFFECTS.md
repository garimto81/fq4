# 시각 폴리시 이펙트 시스템

**Phase 9 Task 9.3 구현 문서**
**버전**: 1.0.0
**작성일**: 2026-02-05

## 개요

전투 피드백과 UI 폴리시를 위한 이펙트 시스템. ObjectPool 기반으로 메모리 효율적인 데미지 팝업, 히트 플래시, 선택 표시기를 구현.

## 핵심 컴포넌트

### 1. DamagePopup (데미지 숫자 팝업)

**위치**: `scripts/effects/damage_popup.gd`
**씬**: `scenes/effects/damage_popup.tscn`

**기능:**
- 전투 데미지를 화면에 시각적으로 표시
- 5가지 타입별 색상/텍스트 구분
- 물리 기반 애니메이션 (중력, 페이드)
- ObjectPool 재활용으로 GC 부하 제거

**데미지 타입:**

| 타입 | 색상 | 표시 | 크기 |
|------|------|------|------|
| `normal` | 흰색 | "99" | 1.0x |
| `critical` | 노랑 | "99!" | 1.5x |
| `heal` | 초록 | "+99" | 1.0x |
| `miss` | 회색 | "MISS" | 1.0x |
| `block` | 하늘색 | "BLOCK" | 1.0x |

**사용 예시:**
```gdscript
# 일반 데미지
EffectManager.spawn_damage_popup(unit.global_position, 50, "normal")

# 크리티컬
EffectManager.spawn_damage_popup(enemy.global_position, 120, "critical")

# 회복
EffectManager.spawn_damage_popup(player.global_position, 30, "heal")
```

**물리 시뮬레이션:**
- 초기 속도: Vector2(0, -50) (위로 발사)
- 중력: +50 (아래로 가속)
- 생존 시간: 1.0초
- 페이드 아웃: alpha = 1.0 - (timer / lifetime)

### 2. HitFlash (피격 플래시 효과)

**위치**: `scripts/effects/hit_flash.gd`

**기능:**
- 유닛 피격 시 색상 플래시
- AccessibilitySystem 연동 (광과민성 대응)
- 타겟의 원본 색상 자동 복원
- Node 컴포넌트 패턴으로 재사용

**사용 예시:**
```gdscript
# 기본 흰색 플래시
EffectManager.spawn_hit_flash(unit_sprite)

# 커스텀 색상 (빨강, 0.2초)
var flash = HitFlash.new()
unit.add_child(flash)
flash.setup(unit_sprite)
flash.flash(Color.RED, 0.2)
```

**AccessibilitySystem 연동:**
- `AccessibilitySystem.can_flash()` 체크
- 광과민성 모드에서 플래시 비활성화
- 대체: 간단한 색상 변경 또는 아이콘 표시

### 3. SelectionIndicator (선택 표시기)

**위치**: `scripts/effects/selection_indicator.gd`

**기능:**
- 선택된 유닛에 펄스 효과
- 부드러운 sin 파동 애니메이션
- 설정 가능한 크기/속도

**파라미터:**
- `base_scale`: 기본 크기 (1.0)
- `pulse_amount`: 펄스 범위 (0.1 = ±10%)
- `pulse_speed`: 펄스 속도 (3.0 rad/s)

**사용 예시:**
```gdscript
# 유닛 씬에 추가
var indicator = SelectionIndicator.new()
indicator.base_scale = 1.2
indicator.pulse_amount = 0.15
indicator.pulse_speed = 4.0
unit.add_child(indicator)
```

**애니메이션 공식:**
```
scale = base_scale + sin(time * pulse_speed) * pulse_amount
```

### 4. EffectManager (전역 관리자)

**위치**: `scripts/autoload/effect_manager.gd`
**Autoload**: `EffectManager` (project.godot)

**기능:**
- ObjectPool 통합 (DamagePopup 풀 자동 등록)
- 통합된 이펙트 생성 API
- HitFlash 컴포넌트 자동 관리

**API:**

```gdscript
# 데미지 팝업 생성 (자동 풀링)
EffectManager.spawn_damage_popup(position: Vector2, amount: int, type: String)

# 히트 플래시 (컴포넌트 자동 추가)
EffectManager.spawn_hit_flash(target: CanvasItem, color: Color)
```

**풀 설정:**
- Pool 이름: `"damage_popup"`
- 초기 크기: 20개
- 자동 확장: 필요 시 런타임 생성

## ObjectPool 통합

### 메모리 최적화

**Before (queue_free):**
```gdscript
func _on_lifetime_end():
    queue_free()  # GC 부하
```

**After (PoolManager):**
```gdscript
func _on_lifetime_end():
    PoolManager.release("damage_popup", self)  # 재활용
```

### 풀 통계 확인

```gdscript
var stats = PoolManager.get_stats()
print("Active: ", stats["damage_popup"]["active"])
print("Pooled: ", stats["damage_popup"]["pooled"])
```

**예상 결과:**
- 평균 동시 활성: 5-10개
- 풀 크기: 10-15개 (자동 조절)
- GC 호출: 95% 감소

## 테스트 씬

**위치**: `scenes/test/effects_test.tscn`
**스크립트**: `scenes/test/effects_test.gd`

**조작법:**

| 입력 | 동작 |
|------|------|
| 마우스 클릭 | 현재 타입 데미지 팝업 생성 |
| `1` | Normal 모드 |
| `2` | Critical 모드 |
| `3` | Heal 모드 |
| `4` | Miss 모드 |
| `5` | Block 모드 |
| `F` | 히트 플래시 테스트 |

**실행 방법:**
```powershell
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/effects_test.tscn
```

**확인 사항:**
- [ ] 데미지 숫자가 위로 떠오르며 페이드 아웃
- [ ] Critical은 1.5배 크기 + 노란색 + "!" 표시
- [ ] Heal은 초록색 + "+" 표시
- [ ] 히트 플래시 후 원래 색상 복원
- [ ] 60 프레임마다 풀 통계 콘솔 출력

## 전투 시스템 연동

### CombatSystem 수정 예시

```gdscript
# scripts/systems/combat_system.gd

func deal_damage(attacker: Unit, target: Unit, amount: int, is_critical: bool) -> void:
    target.take_damage(amount)

    # 데미지 팝업 생성
    var damage_type = "critical" if is_critical else "normal"
    EffectManager.spawn_damage_popup(target.global_position, amount, damage_type)

    # 히트 플래시
    var flash_color = Color.YELLOW if is_critical else Color.WHITE
    EffectManager.spawn_hit_flash(target.get_sprite(), flash_color)

    # 사운드 재생
    AudioManager.play_sfx("hit")

func miss_attack(attacker: Unit, target: Unit) -> void:
    EffectManager.spawn_damage_popup(target.global_position, 0, "miss")
    AudioManager.play_sfx("miss")

func block_attack(attacker: Unit, target: Unit) -> void:
    EffectManager.spawn_damage_popup(target.global_position, 0, "block")
    EffectManager.spawn_hit_flash(target.get_sprite(), Color.LIGHT_BLUE)
    AudioManager.play_sfx("block")
```

### Unit 스크립트 연동

```gdscript
# scripts/units/unit.gd

func heal(amount: int) -> void:
    current_hp = min(current_hp + amount, max_hp)
    EffectManager.spawn_damage_popup(global_position, amount, "heal")
    AudioManager.play_sfx("heal")

func _on_selected() -> void:
    if not selection_indicator:
        selection_indicator = SelectionIndicator.new()
        add_child(selection_indicator)
    selection_indicator.visible = true

func _on_deselected() -> void:
    if selection_indicator:
        selection_indicator.visible = false
```

## 성능 고려사항

### 프레임 드롭 방지

**동시 이펙트 제한:**
```gdscript
# effect_manager.gd에 추가 권장
const MAX_CONCURRENT_POPUPS = 30

func spawn_damage_popup(...) -> void:
    var stats = PoolManager.get_stats()
    if stats["damage_popup"]["active"] >= MAX_CONCURRENT_POPUPS:
        return  # 과부하 방지

    var popup = PoolManager.acquire("damage_popup")
    # ...
```

### 메모리 사용량

- 1개 DamagePopup: ~1KB (Node2D + Label)
- 풀 크기 20개: ~20KB
- 최대 활성 30개: ~30KB
- **총합: ~50KB (무시할 수준)**

### 렌더링 최적화

- Label 폰트: Bitmap 폰트 권장 (MSDF 오버헤드 회피)
- 텍스처 아틀라스: 숫자 스프라이트로 대체 가능
- Z-index: 고정값으로 리오더링 방지

## 확장 가능성

### 추가 이펙트 타입

```gdscript
# effect_manager.gd 확장

const LEVEL_UP_POPUP_SCENE = preload("res://scenes/effects/level_up_popup.tscn")
const BUFF_ICON_SCENE = preload("res://scenes/effects/buff_icon.tscn")

func _ready():
    PoolManager.register_pool("level_up_popup", LEVEL_UP_POPUP_SCENE, 5)
    PoolManager.register_pool("buff_icon", BUFF_ICON_SCENE, 10)

func spawn_level_up_effect(position: Vector2) -> void:
    var effect = PoolManager.acquire("level_up_popup")
    effect.global_position = position
    # ...
```

### 파티클 시스템 연동

```gdscript
# scripts/effects/enhanced_damage_popup.gd

extends DamagePopup

@onready var particles: GPUParticles2D = $Particles

func setup(amount: int, damage_type: String) -> void:
    super.setup(amount, damage_type)

    if damage_type == "critical":
        particles.emitting = true
        particles.process_material.color = Color.YELLOW
```

## 문제 해결

### 팝업이 표시되지 않음

**원인 1**: EffectManager가 Autoload에 등록되지 않음
```gdscript
# project.godot 확인
[autoload]
EffectManager="*res://scripts/autoload/effect_manager.gd"
```

**원인 2**: 씬 파일 경로 오류
```gdscript
# effect_manager.gd
const DAMAGE_POPUP_SCENE = preload("res://scenes/effects/damage_popup.tscn")
# ↑ 경로가 정확한지 확인
```

**원인 3**: Z-index 문제
```gdscript
# damage_popup.tscn에서 Z-index 설정
[node name="DamagePopup" type="Node2D"]
z_index = 100  # 다른 요소 위에 표시
```

### 플래시가 너무 밝음

**해결책**: AccessibilitySystem 연동
```gdscript
# accessibility_system.gd
var reduce_flash_intensity: bool = true

func can_flash() -> bool:
    if reduce_flash_intensity:
        return false  # 플래시 비활성화
    return true
```

### 풀이 고갈됨

**해결책**: 초기 크기 증가 또는 동적 확장
```gdscript
# effect_manager.gd
PoolManager.register_pool("damage_popup", DAMAGE_POPUP_SCENE, 50)  # 20 → 50
```

## 참조

- [ObjectPool 시스템](C:\claude\Fq4\godot\scripts\systems\object_pool.gd)
- [PoolManager](C:\claude\Fq4\godot\scripts\autoload\pool_manager.gd)
- [AccessibilitySystem](C:\claude\Fq4\godot\scripts\autoload\accessibility_system.gd)
- [CombatSystem](C:\claude\Fq4\godot\scripts\systems\combat_system.gd)
