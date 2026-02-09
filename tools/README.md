# FQ4 Asset Extraction Tools

POC 도구 모음: First Queen 4 에셋 추출 및 분석

## 도구 목록

| 도구 | 용도 | 상태 |
|------|------|------|
| `fq4_extractor.py` | 팔레트/RGBE 이미지 추출 | 작동 |
| `text_extractor.py` | 게임 텍스트/대화 추출 | 작동 (암호화됨) |
| `test_extraction.py` | 자동 테스트 | 작동 |

---

## 1. fq4_extractor.py

팔레트 및 RGBE 비트플레인 이미지 추출기

### 기능

- FQ4.RGB 팔레트 추출
- RGBE 4-플레인 이미지 디코딩
- PNG 변환 및 저장

### 사용법

```bash
# 팔레트 추출
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output/

# RGBE 이미지 추출
python tools/fq4_extractor.py decode GAME/FQOP_01 --output output/
```

### 출력

- `palette.png`: 16색 팔레트 시각화
- `{filename}.png`: 디코딩된 이미지

### 기술 세부사항

- 팔레트: 6-bit → 8-bit 색상 변환
- RGBE: 4개 비트플레인 결합
- 해상도: 320×200 (VGA)

---

## 2. text_extractor.py

게임 텍스트/대화 추출기 (FQ4MES)

### 기능

- 오프셋 테이블 파싱
- Shift-JIS 문자열 추출
- Hex + Decoded 덤프

### 사용법

```bash
# 전체 추출
python tools/text_extractor.py GAME/FQ4MES -o output/text

# 구조 분석만
python tools/text_extractor.py GAME/FQ4MES --analyze-only
```

### 출력

- `messages.txt`: 전체 덤프 (hex + decoded)
- `messages_decoded.txt`: 디코딩된 텍스트만

### 파일 구조

```
FQ4MES:
├── Offset Table (0x0000-0x063E): 799 entries × 2 bytes
└── Text Data (0x0640-EOF): Shift-JIS strings (null-terminated)
```

### 현재 제약

**문자 치환 암호 적용됨**

추출된 텍스트는 Shift-JIS로 디코딩되지만 의미는 암호화되어 있음:

```
[001] 、、、、、、釣狐随若、非洗書
      → 실제 의미: 알 수 없음 (치환 테이블 필요)
```

**복호화 방법:**
1. 주파수 분석 (일본어 입자 패턴)
2. Known-Plaintext 공격 (게임 스크린샷 대조)
3. 리버스 엔지니어링 (FQ4.EXE 분석)

---

## 3. test_extraction.py

자동 테스트 스크립트

### 사용법

```bash
python tools/test_extraction.py
```

### 테스트 항목

- 팔레트 로드
- 팔레트 크기 검증 (88 bytes, 16 colors)
- RGBE 디코딩
- 출력 파일 생성 확인

---

## 파일 포맷 참조

### FQ4.RGB (팔레트)

```
Offset  Size  Description
------  ----  -----------
0x0000  88    16 colors × (R, G, B, ?, ?, ?)
              Each component: 6-bit (0-63)
```

### RGBE 이미지

```
{basename}.R_  Red plane
{basename}.G_  Green plane
{basename}.B_  Blue plane
{basename}.E_  Extra/Intensity plane

Width: 320 pixels
Height: 200 pixels
Bits per pixel: 4 (16 colors)
```

### FQ4MES (텍스트)

```
Offset Table (Little-Endian):
[WORD] Message 0 offset
[WORD] Message 1 offset
...
[WORD] Message 798 offset

Text Data:
[Shift-JIS String] 0x00
[Shift-JIS String] 0x00
...
```

상세 분석: `docs/TEXT_FORMAT_ANALYSIS.md`

---

## 요구사항

```bash
pip install Pillow
```

Python 3.7+

---

## Next Steps

1. **CHRBANK/MAPBANK 추출기**
   - 스프라이트/타일 추출
   - 애니메이션 시퀀스 파싱

2. **FQ4MES 암호 해독**
   - 치환 테이블 구축
   - 자동 복호화 도구

3. **BGMBANK 추출기**
   - MIDI/MML 변환
   - 현대 포맷 출력

4. **통합 CLI**
   - 단일 명령으로 전체 추출
   - JSON 메타데이터 생성

---

## 라이선스

MIT License

원본 게임 에셋: © Kure Software Koubou
