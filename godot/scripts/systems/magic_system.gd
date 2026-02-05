extends Node
class_name MagicSystem
## MagicSystem: 마법 시스템 (Architecture Stub)
##
## Phase 3에서 완전 구현 예정. 현재는 인터페이스만 정의.

# 시그널
signal spell_cast(caster, spell: SpellData, target)
signal spell_failed(caster, spell: SpellData, reason: String)
signal mp_changed(unit, new_mp: int, max_mp: int)

## 마법 시전
func cast_spell(caster, spell: SpellData, target = null) -> Dictionary:
	# Stub - Phase 3에서 구현
	if not spell:
		spell_failed.emit(caster, spell, "No spell data")
		return {"success": false, "reason": "No spell data"}

	if not _can_cast(caster, spell):
		spell_failed.emit(caster, spell, "Cannot cast")
		return {"success": false, "reason": "Cannot cast"}

	# MP 소모
	caster.current_mp -= spell.mp_cost
	mp_changed.emit(caster, caster.current_mp, caster.max_mp)

	spell_cast.emit(caster, spell, target)
	return {"success": true}

## 시전 가능 여부 확인
func _can_cast(caster, spell: SpellData) -> bool:
	if not caster.is_alive:
		return false
	if caster.current_mp < spell.mp_cost:
		return false
	return true

## AI가 마법 시전 결정
func ai_should_cast_spell(caster, allies: Array, enemies: Array) -> Dictionary:
	# Stub - Phase 3에서 AI 마법 로직 구현
	# 반환: {"should_cast": bool, "spell": SpellData, "target": Unit}
	return {"should_cast": false, "spell": null, "target": null}
