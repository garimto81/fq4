// AccessibilitySystem - Manages accessibility features and color blind modes
// Based on Godot accessibility_system.gd from FQ4 Remake
// Supports protanopia, deuteranopia, tritanopia color blind modes

enum ColorBlindMode { none, protanopia, deuteranopia, tritanopia }

class AccessibilitySystem {
  ColorBlindMode colorBlindMode = ColorBlindMode.none;
  double fontScale = 1.0; // 0.8 ~ 1.5
  bool highContrast = false;
  bool screenShakeEnabled = true;
  bool flashEffectsEnabled = true;
  bool subtitleEnabled = true;
  bool subtitleBackground = true;

  // Callbacks
  Function()? onSettingsChanged;

  void setColorBlindMode(ColorBlindMode mode) {
    colorBlindMode = mode;
    onSettingsChanged?.call();
  }

  void setFontScale(double scale) {
    fontScale = scale.clamp(0.8, 1.5);
    onSettingsChanged?.call();
  }

  void setHighContrast(bool enabled) {
    highContrast = enabled;
    onSettingsChanged?.call();
  }

  void setScreenShake(bool enabled) {
    screenShakeEnabled = enabled;
  }

  void setFlashEffects(bool enabled) {
    flashEffectsEnabled = enabled;
  }

  void setSubtitleEnabled(bool enabled) {
    subtitleEnabled = enabled;
    onSettingsChanged?.call();
  }

  void setSubtitleBackground(bool enabled) {
    subtitleBackground = enabled;
    onSettingsChanged?.call();
  }

  bool canShakeScreen() => screenShakeEnabled;
  bool canFlash() => flashEffectsEnabled;

  // Serialize for save/load
  Map<String, dynamic> serialize() => {
        'colorBlindMode': colorBlindMode.index,
        'fontScale': fontScale,
        'highContrast': highContrast,
        'screenShakeEnabled': screenShakeEnabled,
        'flashEffectsEnabled': flashEffectsEnabled,
        'subtitleEnabled': subtitleEnabled,
        'subtitleBackground': subtitleBackground,
      };

  void deserialize(Map<String, dynamic> data) {
    colorBlindMode =
        ColorBlindMode.values[data['colorBlindMode'] as int? ?? 0];
    fontScale = (data['fontScale'] as num?)?.toDouble() ?? 1.0;
    highContrast = data['highContrast'] as bool? ?? false;
    screenShakeEnabled = data['screenShakeEnabled'] as bool? ?? true;
    flashEffectsEnabled = data['flashEffectsEnabled'] as bool? ?? true;
    subtitleEnabled = data['subtitleEnabled'] as bool? ?? true;
    subtitleBackground = data['subtitleBackground'] as bool? ?? true;
  }
}
