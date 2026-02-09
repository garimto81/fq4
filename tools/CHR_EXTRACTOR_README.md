# FQ4 CHR Sprite Extractor

First Queen 4 (DOS) CHR 파일에서 스프라이트 타일을 추출하는 도구입니다.

## 구현 상태

**완료:**
- ✅ CHR 파일 파싱 (헤더 없음, raw 타일 데이터)
- ✅ 4bpp planar 형식 디코딩
- ✅ 8x8 및 16x16 타일 추출
- ✅ 스프라이트 시트 생성
- ✅ 개별 타일 저장
- ✅ FQ4.RGB 팔레트 연동
- ✅ 밝은 기본 팔레트 옵션

**제한사항:**
- ⚠️ 일부 CHR 파일(CLASS, MAGIC)의 플레이너 비트 순서가 FONT와 다를 수 있음
- ⚠️ FQ4.RGB 팔레트는 어두운 회색 계열 (일부 파일은 별도 팔레트 필요 가능)

## 설치

```bash
# Pillow 필요
pip install Pillow

# fq4_extractor.py와 같은 디렉토리에 위치 필요 (FQ4PaletteParser 재사용)
```

## 사용법

### 기본 사용

```bash
# 8x8 타일 추출 (FONT.CHR)
python chr_extractor.py C:/claude/Fq4/GAME/FONT.CHR \
  --tile-size 8 \
  --output C:/claude/Fq4/output/sprites/FONT/ \
  --sheet

# 16x16 타일 추출 (CLASS.CHR)
python chr_extractor.py C:/claude/Fq4/GAME/CLASS.CHR \
  --tile-size 16 \
  --output C:/claude/Fq4/output/sprites/CLASS/ \
  --sheet --columns 16
```

### 밝은 팔레트 사용

FQ4.RGB가 너무 어두울 경우:

```bash
python chr_extractor.py C:/claude/Fq4/GAME/MAGIC.CHR \
  --tile-size 8 \
  --bright-palette \
  --output C:/claude/Fq4/output/sprites/MAGIC_BRIGHT/ \
  --sheet
```

### 개별 타일 저장

```bash
# --sheet 플래그 제거
python chr_extractor.py C:/claude/Fq4/GAME/FONT.CHR \
  --tile-size 8 \
  --output C:/claude/Fq4/output/sprites/FONT_TILES/
```

## CHR 파일 분석

| 파일 | 크기 | 8x8 타일 수 | 16x16 타일 수 | 권장 크기 | 상태 |
|------|------|------------|--------------|----------|------|
| FONT.CHR | 3,200 | 100 | 25 | 8x8 | ✅ 정상 |
| MAGIC.CHR | 24,576 | 768 | 192 | 8x8 | ⚠️ 디코딩 이슈 |
| CLASS.CHR | 28,160 | 880 | 220 | 16x16 | ⚠️ 디코딩 이슈 |
| BIGFONT.CHR | 141,344 | 4,417 | 1,104 | 16x16 | ⚠️ 디코딩 이슈 |
| FQ4.CHR | 629,472 | 19,671 | 4,917 | 16x16 | ⚠️ 디코딩 이슈 |

## CHR 형식 상세

### 4bpp Planar Format

각 타일은 4개 bitplane으로 구성됩니다:

**8x8 타일 (32 bytes):**
```
Bytes 0-7:   Plane 0 (bit 0, LSB)
Bytes 8-15:  Plane 1 (bit 1)
Bytes 16-23: Plane 2 (bit 2)
Bytes 24-31: Plane 3 (bit 3, MSB)
```

**16x16 타일 (128 bytes):**
```
Bytes 0-31:  Plane 0 (16 rows × 2 bytes)
Bytes 32-63: Plane 1
Bytes 64-95: Plane 2
Bytes 96-127: Plane 3
```

각 행은 1바이트(8x8) 또는 2바이트(16x16)로 표현되며, MSB부터 픽셀이 저장됩니다.

### 픽셀 값 계산

```
pixel = (plane3_bit << 3) | (plane2_bit << 2) | (plane1_bit << 1) | plane0_bit
```

결과: 4비트 값 (0-15, 16색 인덱스)

## 추출 결과

현재 추출된 파일:

```
C:\claude\Fq4\output\sprites\
├── FONT\
│   └── FONT_sheet.png (128×56, 16×7 tiles)
├── MAGIC\
│   └── MAGIC_sheet.png (256×192, 32×24 tiles)
├── CLASS\
│   └── CLASS_sheet.png (256×224, 16×14 tiles)
├── BIGFONT\
│   └── BIGFONT_sheet.png (320×896, 20×56 tiles)
└── FQ4\
    └── FQ4_sheet.png (512×2464, 32×154 tiles)
```

## 다음 단계

1. 각 CHR 파일의 정확한 플레이너 비트 순서 파악
2. 별도 팔레트 파일 존재 여부 확인 (예: CLASS.RGB)
3. 게임 실행 중 메모리 덤프로 실제 팔레트 확인
4. 타일 애니메이션 프레임 분석

## 관련 도구

- `fq4_extractor.py`: RGBE 이미지 및 FQ4.RGB 팔레트 추출
- `psi_decoder.py`: FQ4.PSI 타일맵 디코딩 (예정)

## 참고 문헌

- DOS VGA 4bpp planar format
- EGA/VGA graphics programming
- First Queen 4 파일 구조 분석
