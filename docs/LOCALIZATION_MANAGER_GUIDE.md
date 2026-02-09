# LocalizationManager 사용 가이드

## 개요

First Queen 4 Remake의 다국어 지원 시스템. 일본어(ja), 한국어(ko), 영어(en) 지원.

## 파일 구조

```
godot/
├── scripts/autoload/
│   └── localization_manager.gd    # AutoLoad 싱글톤
├── resources/translations/
│   ├── ui.csv                     # UI 텍스트
│   ├── system.csv                 # 시스템 메시지
│   ├── dialogues.csv              # 대화 텍스트
│   ├── items.csv                  # 아이템 이름/설명
│   ├── spells.csv                 # 스킬/마법 이름/설명
│   └── enemies.csv                # 적 이름
└── scenes/test/
    ├── localization_test.tscn     # 테스트 씬
    └── localization_test.gd       # 테스트 스크립트
```

## 사용법

### 기본 번역

```gdscript
# 단순 키 번역
var text = LocalizationManager.tr_key("ui.start_game")
# 결과 (ja): "ゲームスタート"
# 결과 (ko): "게임 시작"
# 결과 (en): "Start Game"
```

### 파라미터 치환

```gdscript
# {player_name} 치환
var greeting = LocalizationManager.tr_key("greeting_player", {
    "player_name": "テオ"
})
# 결과 (ja): "こんにちは、テオさん！"
# 결과 (ko): "안녕하세요 テオ님!"
# 결과 (en): "Hello テオ!"

# 복수 파라미터
var damage_msg = LocalizationManager.tr_key("damage_dealt", {
    "target": "ゴブリン",
    "damage": 150
})
# 결과 (ja): "ゴブリンに150のダメージ！"
```

### 로케일 변경

```gdscript
# 로케일 설정
LocalizationManager.set_locale("ko")

# 현재 로케일 확인
var current = LocalizationManager.get_locale()  # "ko"

# 로케일 표시 이름
var name = LocalizationManager.get_current_locale_name()  # "한국어"

# 로케일 변경 시그널
LocalizationManager.locale_changed.connect(_on_locale_changed)
```

### 유틸리티

```gdscript
# 지원 언어 목록
var locales = LocalizationManager.get_supported_locales()  # ["ja", "ko", "en"]

# 로드된 번역 키 개수
var count = LocalizationManager.get_translation_count()

# 특정 키 존재 여부
if LocalizationManager.has_key("ui.start_game"):
    print("Key exists")
```

## CSV 파일 형식

```csv
key,ja,ko,en
ui.start_game,ゲームスタート,게임 시작,Start Game
greeting_player,こんにちは、{player_name}さん！,안녕하세요 {player_name}님!,Hello {player_name}!
```

- **key**: 번역 키 (고유 식별자)
- **ja**: 일본어 번역
- **ko**: 한국어 번역
- **en**: 영어 번역

## 테스트

```powershell
# Godot 에디터에서 실행
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/localization_test.tscn
```

## 번역 추가

1. 해당 CSV 파일 편집 (ui.csv, dialogues.csv 등)
2. 새 행 추가: `key,ja_text,ko_text,en_text`
3. 게임 재시작 또는 로케일 재설정

## 시그널

```gdscript
signal locale_changed(new_locale: String)
```

로케일 변경 시 발생. UI 갱신에 사용.

## 디버그

```gdscript
# 모든 번역 키 출력
LocalizationManager.print_all_keys()
```
