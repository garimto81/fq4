# First Queen 4 Remake Project

First Queen 4 (퍼스트퀸4) HD 리메이크 프로젝트

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **원본** | First Queen 4 (DOS, 1994, Kure Software Koubou) |
| **장르** | 실시간 전술 RPG |
| **핵심 시스템** | Gocha-Kyara (실시간 AI 동료 제어) |
| **타겟 엔진** | Godot 4.4 |

## 디렉토리 구조

```
Fq4/
├── docs/               # PRD 및 기술 문서
│   └── PRD-0001-first-queen-4-remake.md
├── tools/              # 에셋 추출 도구 (POC)
│   ├── fq4_extractor.py    # 팔레트/RGBE 디코더
│   ├── test_extraction.py  # 테스트 스크립트
│   └── README.md           # 도구 문서
└── output/             # 추출된 에셋 (gitignore)
```

## POC 도구 사용법

### 요구사항

```bash
pip install Pillow
```

### 팔레트 추출

```bash
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output/
```

### RGBE 이미지 추출

```bash
python tools/fq4_extractor.py decode GAME/FQOP_01 --output output/
```

## 기술 분석 결과

### 팔레트 (FQ4.RGB)

- 88 bytes, 16색 VGA 팔레트
- 6-bit 색상 (0-63) → 8-bit 변환 필요
- 그레이스케일 + 블루 틴트 팔레트

### RGBE 이미지

- 4개 비트플레인 파일 (.B_, .R_, .G_, .E_)
- 320x200 해상도 (VGA 표준)
- 압축 적용됨 (파일 크기 불균일)

### Bank 파일

| 파일 | 크기 | 용도 |
|------|------|------|
| CHRBANK | 760KB | 캐릭터 스프라이트 |
| MAPBANK | 437KB | 맵 타일 데이터 |
| BGMBANK1/2 | ~35KB | BGM 시퀀스 |

## 로드맵

1. **Phase 0** (현재): POC - 에셋 추출 검증
2. **Phase 1**: MVP - Gocha-Kyara 코어 + 챕터 1-3
3. **Phase 2**: Full Release - 전체 콘텐츠 + Switch 포팅
4. **Phase 3**: Expansion - HD-2D 그래픽 DLC

## 라이선스

- POC 도구 코드: MIT License
- 원본 게임 에셋: Kure Software Koubou 저작권

## 참고 자료

- [First Queen IV - MobyGames](https://www.mobygames.com/game/44091/first-queen-iv/)
- [Kure Software Koubou](http://www.kuresoft.net/)
- [퍼스트 퀸 4 - 나무위키](https://namu.wiki/w/%ED%8D%BC%EC%8A%A4%ED%8A%B8%20%ED%80%B8%204)
