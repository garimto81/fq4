extends Resource
class_name DialogueData
## DialogueData: 대화 데이터 리소스
##
## 대화 노드들과 선택지를 포함합니다.

# 대화 ID
@export var dialogue_id: String = ""

# 대화 제목 (에디터용)
@export var title: String = ""

# 대화 노드 배열
@export var nodes: Array[Dictionary] = []

# 예시 노드 구조:
# {
#   "id": "node_1",
#   "speaker": "주인공",
#   "portrait": "res://assets/portraits/hero.png",
#   "text": "안녕하세요!",
#   "choices": [
#       {"text": "반갑습니다", "next": "node_2"},
#       {"text": "누구세요?", "next": "node_3"}
#   ],
#   "next": "node_2",  # 선택지 없을 때
#   "event": "set_flag:met_npc"  # 선택적 이벤트
# }

# 시작 노드 ID
@export var start_node: String = "start"

## 노드 ID로 노드 찾기
func get_node_by_id(node_id: String) -> Dictionary:
	for node in nodes:
		if node.get("id", "") == node_id:
			return node
	return {}

## 시작 노드 가져오기
func get_start_node() -> Dictionary:
	return get_node_by_id(start_node)

## 다음 노드 가져오기
func get_next_node(current_node: Dictionary, choice_index: int = -1) -> Dictionary:
	# 선택지가 있고 유효한 인덱스인 경우
	var choices = current_node.get("choices", [])
	if not choices.is_empty() and choice_index >= 0 and choice_index < choices.size():
		var next_id = choices[choice_index].get("next", "")
		return get_node_by_id(next_id)

	# 일반 다음 노드
	var next_id = current_node.get("next", "")
	if next_id.is_empty():
		return {}

	return get_node_by_id(next_id)

## JSON에서 로드
static func from_json(json_data: Dictionary) -> DialogueData:
	var data = DialogueData.new()
	data.dialogue_id = json_data.get("id", "")
	data.title = json_data.get("title", "")
	data.start_node = json_data.get("start_node", "start")

	for node in json_data.get("nodes", []):
		data.nodes.append(node)

	return data

## JSON으로 내보내기
func to_json() -> Dictionary:
	return {
		"id": dialogue_id,
		"title": title,
		"start_node": start_node,
		"nodes": nodes
	}
