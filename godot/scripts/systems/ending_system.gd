extends Node
class_name EndingSystem
## EndingSystem: 엔딩 판정 및 크레딧 시스템
##
## 플레이어 생존/사망 상황, 챕터 클리어 여부에 따라 GOOD/NORMAL/BAD 엔딩 결정

enum EndingType {
	GOOD,    # 모든 파티원 생존 + 모든 챕터 클리어
	NORMAL,  # 일부 파티원 사망 + 메인 스토리 완료
	BAD      # 주인공만 생존
}

# 시그널
signal ending_determined(ending_type: EndingType)
signal ending_started(ending_type: EndingType)
signal ending_completed()

## 엔딩 판정
func determine_ending() -> EndingType:
	# ProgressionSystem 접근
	var progression: Node = get_node_or_null("/root/ProgressionSystem")
	if not progression:
		push_error("[EndingSystem] ProgressionSystem not found")
		return EndingType.BAD

	# 생존 파티원 수 계산
	var alive_units = GameManager.player_units.filter(func(u): return u.is_alive)
	var alive_count = alive_units.size()
	var total_count = GameManager.player_units.size()

	# 게임 클리어 여부 (챕터 3 완료 또는 demon_king_defeated 플래그)
	var all_chapters_cleared = progression.has_flag("demon_king_defeated") or progression.is_chapter_cleared(3)

	# 엔딩 조건 판정
	if alive_count == total_count and all_chapters_cleared:
		# GOOD: 모든 파티원 생존 + 모든 챕터 클리어
		return EndingType.GOOD
	elif alive_count == 1:
		# BAD: 주인공만 생존
		return EndingType.BAD
	else:
		# NORMAL: 일부 사망 + 스토리 완료
		return EndingType.NORMAL

## 엔딩 시작
func start_ending(ending_type: EndingType) -> void:
	ending_started.emit(ending_type)

	# 엔딩 대화 로드
	var dialogue_path = "res://resources/dialogues/endings/%s_ending.tres" % EndingType.keys()[ending_type].to_lower()

	# DialogueSystem이 존재하면 대화 재생
	var dialogue_system: Node = get_node_or_null("/root/DialogueSystem")
	if dialogue_system and dialogue_system.has_method("load_and_start"):
		if ResourceLoader.exists(dialogue_path):
			dialogue_system.load_and_start(dialogue_path)
			await dialogue_system.dialogue_ended
		else:
			push_warning("[EndingSystem] Dialogue not found: %s" % dialogue_path)

	# 크레딧 씬으로 전환
	ending_completed.emit()
	var credits_path = "res://scenes/ui/credits.tscn"
	if ResourceLoader.exists(credits_path):
		get_tree().change_scene_to_file(credits_path)
	else:
		push_warning("[EndingSystem] Credits scene not found, returning to title")
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

## 엔딩 설명 가져오기
func get_ending_description(ending_type: EndingType) -> String:
	match ending_type:
		EndingType.GOOD:
			return "모든 동료와 함께 마왕을 물리치고 왕국에 평화가 찾아왔다."
		EndingType.NORMAL:
			return "큰 희생 끝에 마왕을 물리쳤지만, 잃어버린 것도 많았다."
		EndingType.BAD:
			return "홀로 살아남아 마왕을 물리쳤지만, 모든 것을 잃었다."
	return ""

## 엔딩 트리거 (게임 클리어 시 호출)
func trigger_ending() -> void:
	var ending_type = determine_ending()
	ending_determined.emit(ending_type)

	print("[EndingSystem] Ending determined: %s" % EndingType.keys()[ending_type])
	print("[EndingSystem] Description: %s" % get_ending_description(ending_type))

	await start_ending(ending_type)
