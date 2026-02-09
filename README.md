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
│   ├── text_extractor.py   # 텍스트/대화 추출기
│   ├── test_extraction.py  # 테스트 스크립트
│   └── README.md           # 도구 문서
└── output/             # 추출된 에셋 (gitignore)
    ├── images/         # 추출된 이미지
    └── text/           # 추출된 텍스트
```

## POC 도구 사용법

### 요구사항

```bash
pip install Pillow
```

### 전체 에셋 추출 (권장)

```bash
cd C:\claude\Fq4
python tools/fq4_extractor.py extract-all --output output
```

**추출 항목:**
- 15개 RGBE 이미지 (오프닝, UI, 캐릭터 초상화)
- 7개 CHR 스프라이트 파일 (26,000+ 타일)
- 5개 Bank 파일 (캐릭터, 맵, BGM, 폰트)
- FQ4MES 텍스트 (799개 문자열)

### 개별 명령어

#### RGBE 이미지 일괄 추출

```bash
python tools/fq4_extractor.py decode-all --output output/images
```

#### CHR 스프라이트 추출

```bash
# 스프라이트 시트 생성
python tools/fq4_extractor.py chr GAME/FQ4.CHR --output output/sprites

# 개별 타일 저장
python tools/fq4_extractor.py chr GAME/FONT.CHR --output output/sprites --individual
```

#### Bank 파일 분해

```bash
python tools/fq4_extractor.py bank GAME/CHRBANK --output output/chrbank
```

#### 텍스트 추출

```bash
python tools/fq4_extractor.py text GAME/FQ4MES --output output/text/messages.txt
```

#### 팔레트 확인

```bash
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output/
```

**출력 구조:**
```
output/
├── palette.png              # 팔레트 스와치
├── images/                  # RGBE 이미지
│   ├── FQOP_01.png ~ FQOP_10.png
│   ├── FQ4G16.png
│   └── SUEMI_A1.png ~ A3.png
├── sprites/                 # CHR 스프라이트 시트
│   ├── FQ4/FQ4_sheet.png (19296 타일)
│   ├── BIGFONT/BIGFONT_sheet.png
│   └── FONT/FONT_sheet.png
├── bank/                    # Bank 파일 엔트리
│   ├── CHRBANK/ (177 엔트리)
│   ├── MAPBANK/ (189 엔트리)
│   └── BGMBANK1/ (41 엔트리)
└── text/
    └── messages.txt         # 799개 게임 텍스트
```

## 기술 분석 결과

### 팔레트 (FQ4.RGB)

- 88 bytes, 16색 VGA 팔레트
- 6-bit 색상 (0-63) → 8-bit 변환 필요
- 그레이스케일 + 블루 틴트 팔레트

### RGBE 이미지

- 4개 비트플레인 파일 (.B_, .R_, .G_, .E_)
- 320x200 해상도 (VGA 표준)
- 4bpp (16색) 인덱스 컬러
- 15개 세트 추출 완료

### CHR 스프라이트

| 파일 | 크기 | 타일 수 | 용도 |
|------|------|---------|------|
| FQ4.CHR | 615KB | 19,296 | 메인 스프라이트 |
| BIGFONT.CHR | 139KB | 4,360 | 대형 폰트 |
| FONT.CHR | 3.2KB | 100 | 일반 폰트 |
| CLASS.CHR | 28KB | 875 | 클래스 아이콘 |
| MAGIC.CHR | 24KB | 750 | 마법 이펙트 |
| FQ4P.CHR | 26KB | 812 | 플레이어 스프라이트 |
| FQ4P2.CHR | 26KB | 812 | 플레이어 스프라이트 2 |

**포맷:** 4bpp planar, 8x8 타일, 타일당 32바이트

### Bank 파일

| 파일 | 크기 | 엔트리 수 | 용도 |
|------|------|----------|------|
| CHRBANK | 743KB | 177 | 캐릭터 데이터 |
| MAPBANK | 427KB | 189 | 맵 타일 데이터 |
| BGMBANK1 | 36KB | 41 | BGM 시퀀스 1 |
| BGMBANK2 | 34KB | 41 | BGM 시퀀스 2 |
| FQFBANK | 69KB | 33 | 폰트/얼굴 데이터 |

**포맷:** 16-bit offset table + 압축 엔트리

### FQ4MES (텍스트 파일)

- 65,494 bytes
- 799개 메시지
- 오프셋 테이블 (1,598 bytes) + Shift-JIS 문자열
- **주의**: 문자 치환 암호 사용 추정 (복호화 필요)

## 로드맵

1. **Phase 0** (현재): POC - 에셋 추출 검증
2. **Phase 1**: MVP - Gocha-Kyara 코어 + 챕터 1-3
3. **Phase 2**: Full Release - 전체 콘텐츠 + Switch 포팅
4. **Phase 3**: Expansion - HD-2D 그래픽 DLC

## 문서

### 기술 문서

- [PRD-0001: First Queen 4 리메이크 기획서](./docs/PRD-0001-first-queen-4-remake.md)
- [FQ4MES 텍스트 복호화 최종 보고서](./docs/FQ4MES_FINAL_REPORT.md)
- **[FQ4 게임 대사 모음](./docs/FQ4_DIALOGUE_COLLECTION.md)** - 복호화된 800개 메시지 분석 및 캐릭터별 대사

### 관련 분석 문서

- [확장 매핑 결과](./docs/EXTENDED_MAPPING_RESULTS.md)
- [알려진 단어 분석](./docs/KNOWN_WORDS_ANALYSIS.md)
- [텍스트 암호 분석](./docs/TEXT_CIPHER_ANALYSIS.md)

## 라이선스

- POC 도구 코드: MIT License
- 원본 게임 에셋: Kure Software Koubou 저작권

## 참고 자료

- [First Queen IV - MobyGames](https://www.mobygames.com/game/44091/first-queen-iv/)
- [Kure Software Koubou](http://www.kuresoft.net/)
- [퍼스트 퀸 4 - 나무위키](https://namu.wiki/w/%ED%8D%BC%EC%8A%A4%ED%8A%B8%20%ED%80%B8%204)
