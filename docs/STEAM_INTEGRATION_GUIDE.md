# Steam Integration Guide - First Queen 4 HD Remake

**Version**: 1.0.0
**Last Updated**: 2026-02-05

Steam 연동 가이드. GodotSteam 플러그인을 사용한 업적, 리더보드, 클라우드 저장 구현.

---

## 목차

1. [GodotSteam 설치](#1-godotsteam-설치)
2. [Steam App ID 설정](#2-steam-app-id-설정)
3. [업적 시스템](#3-업적-시스템)
4. [리더보드](#4-리더보드)
5. [클라우드 저장](#5-클라우드-저장)
6. [리치 프레즌스](#6-리치-프레즌스)
7. [테스트 방법](#7-테스트-방법)
8. [배포 체크리스트](#8-배포-체크리스트)

---

## 1. GodotSteam 설치

### 1.1. 다운로드

공식 사이트: https://godotsteam.com/

**권장 버전:** GDExtension (Godot 4.x 전용)

```powershell
# 릴리즈 페이지에서 다운로드
# https://github.com/GodotSteam/GodotSteam/releases

# 파일 예시: godotsteam-gdextension-4.x-win64.zip
```

### 1.2. 설치

1. 압축 해제 후 `addons/godotsteam/` 폴더에 복사
2. Godot 에디터 열기
3. **Project → Project Settings → Plugins**
4. **GodotSteam** 체크박스 활성화
5. 에디터 재시작

### 1.3. 검증

```gdscript
# project.godot에서 자동 감지 여부 확인
func _ready():
    print(Engine.has_singleton("Steam"))  # true여야 함
```

---

## 2. Steam App ID 설정

### 2.1. Steamworks 앱 생성

1. [Steamworks 파트너](https://partner.steamgames.com/) 로그인
2. **Apps & Packages → Create New App**
3. App ID 발급 (예: 1234560)

### 2.2. App ID 설정

**파일 위치:** `godot/scripts/autoload/steam_manager.gd`

```gdscript
# 테스트용 (Spacewar)
const STEAM_APP_ID: int = 480

# 출시용 (발급받은 ID로 교체)
const STEAM_APP_ID: int = 1234560
```

**환경 변수 설정 (로컬 테스트):**

```powershell
# steam_appid.txt 파일 생성 (실행 파일과 동일 경로)
echo 480 > steam_appid.txt
```

### 2.3. AutoLoad 등록

**Project → Project Settings → AutoLoad**

| Name | Path | Singleton |
|------|------|-----------|
| SteamManager | `res://scripts/autoload/steam_manager.gd` | ✓ |

---

## 3. 업적 시스템

### 3.1. Steamworks 업적 정의

**Steamworks → Technical Requirements → Stats & Achievements**

| API Name | Display Name | Description | Hidden |
|----------|--------------|-------------|--------|
| `FIRST_BLOOD` | First Blood | 첫 전투 승리 | No |
| `SQUAD_MASTER` | Squad Master | 부대 전체 생존으로 챕터 클리어 | No |
| `GOCHA_KYARA_PRO` | Gocha-Kyara Pro | AI 동료가 100명 처치 | Yes |
| `ALL_CHAPTERS` | Legend Reborn | 전체 챕터 완료 | No |

### 3.2. 코드 구현

**업적 해금:**

```gdscript
# 전투 승리 시
func _on_battle_won():
    SteamManager.unlock_achievement("FIRST_BLOOD")

# 챕터 클리어 시 조건 체크
func _on_chapter_complete():
    if all_units_alive:
        SteamManager.unlock_achievement("SQUAD_MASTER")
```

**진행도 업적 (Stat 기반):**

```gdscript
# 동료 처치 카운트
func _on_ai_unit_kill():
    ai_kills += 1
    SteamManager.set_achievement_progress("GOCHA_KYARA_PRO", ai_kills, 100)
```

### 3.3. 디버그 명령

```gdscript
# 모든 업적 초기화 (테스트용)
func reset_all_achievements():
    SteamManager.clear_achievement("FIRST_BLOOD")
    SteamManager.clear_achievement("SQUAD_MASTER")
    # ...
```

---

## 4. 리더보드

### 4.1. Steamworks 리더보드 생성

**Steamworks → Stats & Achievements → Leaderboards**

| Name | API Name | Sort Method | Display Type |
|------|----------|-------------|--------------|
| Chapter 1 Speed | `chapter1_time` | Ascending | Time (Milliseconds) |
| Total Kills | `total_kills` | Descending | Numeric |
| Survival Rate | `survival_rate` | Descending | Numeric |

### 4.2. 점수 제출

```gdscript
# 챕터 클리어 시간 기록
func _on_chapter_clear(chapter: int, time_ms: int):
    var leaderboard_name = "chapter%d_time" % chapter
    SteamManager.submit_score(leaderboard_name, time_ms)

# 총 처치 수
func submit_final_stats(kills: int):
    SteamManager.submit_score("total_kills", kills)
```

### 4.3. 리더보드 조회

```gdscript
# GodotSteam API 직접 사용
func fetch_leaderboard(leaderboard_name: String):
    if not SteamManager.is_steam_running:
        return

    Steam.findLeaderboard(leaderboard_name)
    await Steam.leaderboard_find_result

    Steam.downloadLeaderboardEntries(0, 10, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL)
    var entries = await Steam.leaderboard_scores_downloaded

    for entry in entries:
        print("Rank: %d, Score: %d, Name: %s" % [entry.global_rank, entry.score, entry.steam_id])
```

---

## 5. 클라우드 저장

### 5.1. Steamworks 클라우드 활성화

**Steamworks → Technical Requirements → Cloud**

- **Enable Steam Cloud Sync**: Yes
- **Byte Quota Per User**: 100 MB (권장)
- **File Count Limit**: 100 files

### 5.2. 세이브 파일 업로드

```gdscript
# SaveSystem과 통합
func save_game_to_steam(slot: int):
    var save_data = SaveSystem.create_save_data()
    var json_string = JSON.stringify(save_data)
    var bytes = json_string.to_utf8_buffer()

    var filename = "save_slot_%d.json" % slot
    var success = SteamManager.save_to_cloud(filename, bytes)

    if success:
        print("[Steam] Save uploaded: %s" % filename)
    else:
        print("[Steam] Cloud save failed, using local fallback")
        SaveSystem.save_game(slot)  # 로컬 저장 폴백
```

### 5.3. 클라우드에서 로드

```gdscript
func load_game_from_steam(slot: int):
    var filename = "save_slot_%d.json" % slot
    var bytes = SteamManager.load_from_cloud(filename)

    if bytes.is_empty():
        print("[Steam] No cloud save, loading local")
        SaveSystem.load_game(slot)
        return

    var json_string = bytes.get_string_from_utf8()
    var save_data = JSON.parse_string(json_string)
    SaveSystem.apply_save_data(save_data)
```

### 5.4. 충돌 해결

```gdscript
# 로컬과 클라우드 타임스탬프 비교
func sync_saves():
    var local_time = SaveSystem.get_save_timestamp(0)
    var cloud_bytes = SteamManager.load_from_cloud("save_slot_0.json")

    if cloud_bytes.is_empty():
        # 클라우드에 없음 → 업로드
        save_game_to_steam(0)
    else:
        var cloud_data = JSON.parse_string(cloud_bytes.get_string_from_utf8())
        var cloud_time = cloud_data.get("timestamp", 0)

        if cloud_time > local_time:
            # 클라우드가 최신 → 다운로드
            SaveSystem.apply_save_data(cloud_data)
        else:
            # 로컬이 최신 → 업로드
            save_game_to_steam(0)
```

---

## 6. 리치 프레즌스

### 6.1. Steamworks 프레즌스 토큰

**Steamworks → Technical Requirements → Rich Presence**

| Token | Display String (Korean) |
|-------|-------------------------|
| `#Playing` | {#chapter}에서 플레이 중 |
| `#MainMenu` | 메인 메뉴 |
| `#InBattle` | {#enemy}와 전투 중 |

### 6.2. 게임 상태 업데이트

```gdscript
# 챕터 진입
func _on_chapter_start(chapter_id: int, chapter_name: String):
    SteamManager.update_chapter_presence(chapter_id, chapter_name)

# 전투 시작
func _on_battle_start(enemy_name: String):
    SteamManager.set_rich_presence("steam_display", "#InBattle")
    SteamManager.set_rich_presence("enemy", enemy_name)

# 메인 메뉴
func _on_main_menu():
    SteamManager.set_rich_presence("steam_display", "#MainMenu")
```

---

## 7. 테스트 방법

### 7.1. 로컬 테스트 (Spacewar)

```powershell
# 1. steam_appid.txt 생성
echo 480 > C:\claude\Fq4\godot\steam_appid.txt

# 2. Steam 클라이언트 실행 (로그인 필수)
# 3. Godot 에디터에서 게임 실행

# 4. 콘솔 확인
# [Steam] Initialized: YourName (ID: 76561198...)
```

### 7.2. 업적 테스트

```gdscript
# 디버그 명령
func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:
            SteamManager.unlock_achievement("FIRST_BLOOD")
        elif event.keycode == KEY_F2:
            SteamManager.clear_achievement("FIRST_BLOOD")
```

### 7.3. Steam Overlay 확인

- **Shift + Tab**: Overlay 열기 (업적, 친구 목록 확인)

---

## 8. 배포 체크리스트

### 8.1. Steamworks 설정

- [ ] App ID를 테스트용(480)에서 실제 ID로 변경
- [ ] 모든 업적 정의 완료 (이름, 설명, 아이콘)
- [ ] 리더보드 생성 및 정렬 방식 확인
- [ ] 클라우드 스토리지 활성화
- [ ] 리치 프레즌스 토큰 등록

### 8.2. 코드 검증

- [ ] `steam_manager.gd`에서 주석 해제
- [ ] App ID 하드코딩 확인
- [ ] `steam_appid.txt` 빌드에서 제외 (.gitignore 추가)
- [ ] 업적 unlock 조건 모두 테스트

### 8.3. 빌드 설정

```powershell
# Export Preset 설정
# Project → Export → Add → Windows Desktop
# Custom Template: GodotSteam 포함된 템플릿 사용

# steam_api64.dll 포함 확인
# 빌드 결과물 폴더에 steam_api64.dll 복사
```

### 8.4. Steam Depot 업로드

```powershell
# ContentBuilder 사용
# Steamworks SDK의 tools/ContentBuilder 폴더

# 1. app_build_1234560.vdf 작성
# 2. 빌드 실행
steamcmd +login username +run_app_build app_build_1234560.vdf +quit
```

---

## 9. API 레퍼런스

### 9.1. SteamManager 메서드

| 메서드 | 반환 타입 | 설명 |
|--------|----------|------|
| `unlock_achievement(api_name)` | `bool` | 업적 해금 |
| `set_achievement_progress(api_name, current, max)` | `void` | 진행도 업적 |
| `clear_achievement(api_name)` | `void` | 업적 초기화 (디버그) |
| `submit_score(leaderboard, score)` | `void` | 리더보드 점수 제출 |
| `set_rich_presence(key, value)` | `void` | 리치 프레즌스 업데이트 |
| `update_chapter_presence(chapter, name)` | `void` | 챕터 프레즌스 자동 설정 |
| `save_to_cloud(filename, data)` | `bool` | 클라우드 저장 |
| `load_from_cloud(filename)` | `PackedByteArray` | 클라우드 로드 |

### 9.2. 시그널

| 시그널 | 매개변수 | 설명 |
|--------|----------|------|
| `steam_initialized` | `success: bool` | Steam 초기화 완료 |
| `overlay_toggled` | `active: bool` | Overlay 열림/닫힘 |

---

## 10. 트러블슈팅

### 10.1. "Steam not running" 에러

**원인:** Steam 클라이언트가 실행되지 않음

**해결:**
```powershell
# Steam 클라이언트 시작 후 게임 실행
# 또는 steam:// 프로토콜로 자동 시작
start steam://rungameid/480
```

### 10.2. 업적이 해금되지 않음

**확인 사항:**
1. `Steam.storeStats()` 호출 여부
2. Steamworks에서 업적이 Published 상태인지 확인
3. `Steam.run_callbacks()` 호출 여부 (매 프레임)

### 10.3. 클라우드 저장 실패

**확인:**
```gdscript
# 클라우드 활성화 여부
print(Steam.isCloudEnabledForApp())
print(Steam.isCloudEnabledForAccount())

# 할당량 확인
var quota = Steam.getQuota()
print("Available: %d / %d bytes" % [quota[0], quota[1]])
```

---

## 11. 참고 자료

- **GodotSteam 공식 문서**: https://godotsteam.com/
- **Steamworks SDK**: https://partner.steamgames.com/doc/sdk
- **업적 가이드**: https://partner.steamgames.com/doc/features/achievements
- **리더보드 가이드**: https://partner.steamgames.com/doc/features/leaderboards
- **클라우드 저장 가이드**: https://partner.steamgames.com/doc/features/cloud

---

## 변경 이력

| 버전 | 날짜 | 변경 사항 |
|------|------|----------|
| 1.0.0 | 2026-02-05 | 초기 작성 |
