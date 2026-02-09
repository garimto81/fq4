extends Node
## LocalizationManager: 다국어 지원 시스템
##
## 일본어(ja), 한국어(ko), 영어(en) 지원
## CSV 기반 번역 데이터 로드 및 파라미터 치환

const SUPPORTED_LOCALES = ["ja", "ko", "en"]
const TRANSLATIONS_PATH = "res://resources/translations/"

var current_locale: String = "ja"
var translations: Dictionary = {}  # key -> translated text
var loaded_files: Array[String] = []

signal locale_changed(new_locale: String)

func _ready() -> void:
	# 시스템 언어 감지 후 기본 로케일 설정
	var system_locale = OS.get_locale_language()
	if system_locale in SUPPORTED_LOCALES:
		set_locale(system_locale)
	else:
		set_locale("ja")  # 기본값 (원본 게임 언어)

## 로케일 변경
func set_locale(locale: String) -> void:
	if locale not in SUPPORTED_LOCALES:
		push_warning("[LocalizationManager] Unsupported locale: " + locale)
		return

	current_locale = locale
	_load_all_translations()
	locale_changed.emit(locale)
	print("[LocalizationManager] Locale set to: " + locale)

## 현재 로케일 반환
func get_locale() -> String:
	return current_locale

## 번역 키로 텍스트 가져오기
##
## 파라미터 치환 지원:
## tr_key("greeting", {"player_name": "テオ"}) -> "こんにちは、{player_name}さん" -> "こんにちは、テオさん"
func tr_key(key: String, params: Dictionary = {}) -> String:
	var text = translations.get(key, key)  # 키가 없으면 키 자체 반환

	# 파라미터 치환: {player_name} -> params["player_name"]
	for param_key in params:
		text = text.replace("{" + param_key + "}", str(params[param_key]))

	return text

## 모든 번역 파일 로드
func _load_all_translations() -> void:
	translations.clear()
	loaded_files.clear()

	# CSV 파일들 로드
	var files = ["ui.csv", "dialogues.csv", "items.csv", "spells.csv", "enemies.csv", "system.csv"]
	for file in files:
		_load_csv_file(TRANSLATIONS_PATH + file)

	print("[LocalizationManager] Loaded " + str(loaded_files.size()) + " translation files")

## CSV 파일 로드 (key,ja,ko,en 형식)
func _load_csv_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		# 파일이 없어도 경고하지 않음 (선택적 번역 파일)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[LocalizationManager] Failed to open: " + path)
		return

	# 첫 줄: 헤더 (key,ja,ko,en)
	var header = file.get_csv_line()
	var locale_index = header.find(current_locale)
	if locale_index < 0:
		push_warning("[LocalizationManager] Locale '" + current_locale + "' not found in: " + path)
		return

	# 나머지 줄: 번역 데이터
	var line_count = 0
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() > locale_index:
			var key = line[0]
			var value = line[locale_index]
			if not key.is_empty() and not value.is_empty():
				translations[key] = value
				line_count += 1

	loaded_files.append(path)
	print("[LocalizationManager] Loaded " + str(line_count) + " keys from: " + path)

## 지원 언어 목록
func get_supported_locales() -> Array:
	return SUPPORTED_LOCALES.duplicate()

## 로케일 표시 이름
func get_locale_name(locale: String) -> String:
	match locale:
		"ja": return "日本語"
		"ko": return "한국어"
		"en": return "English"
	return locale

## 현재 로케일 표시 이름
func get_current_locale_name() -> String:
	return get_locale_name(current_locale)

## 로드된 번역 파일 목록
func get_loaded_files() -> Array[String]:
	return loaded_files.duplicate()

## 로드된 번역 키 개수
func get_translation_count() -> int:
	return translations.size()

## 특정 키 존재 여부 확인
func has_key(key: String) -> bool:
	return key in translations

## 디버그: 모든 번역 키 출력
func print_all_keys() -> void:
	print("[LocalizationManager] Translation keys:")
	for key in translations.keys():
		print("  - " + key + " = " + translations[key])
