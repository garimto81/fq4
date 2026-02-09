extends Node
## test_spell_database.gd
## SpellDatabase 및 SpellData 확장 테스트

func _ready() -> void:
	print("\n=== SpellDatabase 테스트 시작 ===\n")

	test_create_all_spells()
	test_spell_types()
	test_element_types()
	test_spell_filtering()

	print("\n=== 테스트 완료 ===")
	get_tree().quit()

## 모든 마법 생성 테스트
func test_create_all_spells() -> void:
	print("--- 모든 마법 생성 테스트 ---")
	var spell_ids = SpellDatabase.get_all_spell_ids()
	print("총 마법 수: %d" % spell_ids.size())

	for spell_id in spell_ids:
		var spell = SpellDatabase.create_spell(spell_id)
		if spell:
			print("✓ %s (%s) - MP: %d, Power: %d, Range: %.1f" % [
				spell.spell_name,
				_spell_type_to_string(spell.spell_type),
				spell.mp_cost,
				spell.base_power,
				spell.cast_range
			])
		else:
			push_error("✗ Failed to create spell: %s" % spell_id)
	print()

## 마법 타입별 테스트
func test_spell_types() -> void:
	print("--- 마법 타입별 테스트 ---")

	var damage_spells = SpellDatabase.get_spells_by_type(SpellData.SpellType.DAMAGE)
	print("공격 마법: %d개 - %s" % [damage_spells.size(), str(damage_spells)])

	var heal_spells = SpellDatabase.get_spells_by_type(SpellData.SpellType.HEAL)
	print("회복 마법: %d개 - %s" % [heal_spells.size(), str(heal_spells)])

	var buff_spells = SpellDatabase.get_spells_by_type(SpellData.SpellType.BUFF)
	print("버프 마법: %d개 - %s" % [buff_spells.size(), str(buff_spells)])

	var debuff_spells = SpellDatabase.get_spells_by_type(SpellData.SpellType.DEBUFF)
	print("디버프 마법: %d개 - %s" % [debuff_spells.size(), str(debuff_spells)])
	print()

## 속성별 테스트
func test_element_types() -> void:
	print("--- 속성별 마법 테스트 ---")

	var fire_spells = SpellDatabase.get_spells_by_element(SpellData.ElementType.FIRE)
	print("화염 마법: %d개 - %s" % [fire_spells.size(), str(fire_spells)])

	var ice_spells = SpellDatabase.get_spells_by_element(SpellData.ElementType.ICE)
	print("빙결 마법: %d개 - %s" % [ice_spells.size(), str(ice_spells)])

	var holy_spells = SpellDatabase.get_spells_by_element(SpellData.ElementType.HOLY)
	print("신성 마법: %d개 - %s" % [holy_spells.size(), str(holy_spells)])
	print()

## 특정 마법 상세 테스트
func test_spell_filtering() -> void:
	print("--- 특정 마법 상세 테스트 ---")

	# Fire Ball 테스트
	var fire_ball = SpellDatabase.create_spell("fire_ball")
	if fire_ball:
		print("Fire Ball 상세:")
		print("  타입: %s" % _spell_type_to_string(fire_ball.spell_type))
		print("  속성: %s" % _element_to_string(fire_ball.element))
		print("  타겟: %s" % _target_type_to_string(fire_ball.target_type))
		print("  MP: %d, 위력: %d, 사거리: %.1f, 범위: %.1f" % [
			fire_ball.mp_cost,
			fire_ball.base_power,
			fire_ball.cast_range,
			fire_ball.area_radius
		])
		print("  쿨다운: %.1f초, 시전: %.1f초" % [fire_ball.cooldown, fire_ball.cast_time])

	# Shield 버프 테스트
	var shield = SpellDatabase.create_spell("shield")
	if shield:
		print("\nShield 상세:")
		print("  타입: %s (버프 스탯: %d, 값: %.1f, 지속: %.1f초)" % [
			_spell_type_to_string(shield.spell_type),
			shield.buff_stat,
			shield.buff_value,
			shield.buff_duration
		])

	# Slow 디버프 테스트
	var slow = SpellDatabase.create_spell("slow")
	if slow:
		print("\nSlow 상세:")
		print("  타입: %s (디버프 스탯: %d, 값: %.1f, 지속: %.1f초)" % [
			_spell_type_to_string(slow.spell_type),
			slow.buff_stat,
			slow.buff_value,
			slow.buff_duration
		])
	print()

## Helper functions
func _spell_type_to_string(type: SpellData.SpellType) -> String:
	match type:
		SpellData.SpellType.DAMAGE: return "공격"
		SpellData.SpellType.HEAL: return "회복"
		SpellData.SpellType.BUFF: return "버프"
		SpellData.SpellType.DEBUFF: return "디버프"
		SpellData.SpellType.SUMMON: return "소환"
		_: return "알 수 없음"

func _element_to_string(element: SpellData.ElementType) -> String:
	match element:
		SpellData.ElementType.NONE: return "무속성"
		SpellData.ElementType.FIRE: return "화염"
		SpellData.ElementType.ICE: return "빙결"
		SpellData.ElementType.LIGHTNING: return "번개"
		SpellData.ElementType.HOLY: return "신성"
		SpellData.ElementType.DARK: return "암흑"
		_: return "알 수 없음"

func _target_type_to_string(target: SpellData.TargetType) -> String:
	match target:
		SpellData.TargetType.SELF: return "자신"
		SpellData.TargetType.SINGLE_ALLY: return "아군 단일"
		SpellData.TargetType.SINGLE_ENEMY: return "적 단일"
		SpellData.TargetType.ALL_ALLIES: return "아군 전체"
		SpellData.TargetType.ALL_ENEMIES: return "적 전체"
		SpellData.TargetType.AREA: return "범위"
		_: return "알 수 없음"
