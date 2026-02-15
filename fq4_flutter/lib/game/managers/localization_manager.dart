// LocalizationManager - Manages game translations and locale switching
// Based on Godot localization_manager.gd from FQ4 Remake
// Supports Japanese (ja), Korean (ko), and English (en)

class LocalizationManager {
  static const List<String> supportedLocales = ['ja', 'ko', 'en'];

  String currentLocale = 'ja'; // default: Japanese (original game language)
  final Map<String, String> _translations = {}; // key -> translated text

  // Callbacks
  Function(String locale)? onLocaleChanged;

  void setLocale(String locale) {
    if (!supportedLocales.contains(locale)) return;
    currentLocale = locale;
    onLocaleChanged?.call(locale);
  }

  String getLocale() => currentLocale;

  // Translate with parameter substitution: {player_name} -> params['player_name']
  String tr(String key, [Map<String, String> params = const {}]) {
    var text = _translations[key] ?? key; // return key if not found
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  // Load translations from Map<String, Map<String, String>> format
  // e.g., {'UI_START': {'ja': 'はじめる', 'ko': '시작', 'en': 'Start'}}
  void loadTranslations(Map<String, Map<String, String>> data) {
    _translations.clear();
    for (final entry in data.entries) {
      final localeMap = entry.value;
      final text = localeMap[currentLocale] ?? localeMap['ja'] ?? entry.key;
      _translations[entry.key] = text;
    }
  }

  // Load from flat map (key -> text for current locale)
  void loadFlatTranslations(Map<String, String> data) {
    _translations.addAll(data);
  }

  bool hasKey(String key) => _translations.containsKey(key);
  int get translationCount => _translations.length;

  String getLocaleName(String locale) {
    switch (locale) {
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      default:
        return locale;
    }
  }

  String get currentLocaleName => getLocaleName(currentLocale);

  // Built-in sample translations for testing
  static Map<String, Map<String, String>> sampleTranslations() {
    return {
      'UI_START': {'ja': 'はじめる', 'ko': '시작', 'en': 'Start'},
      'UI_CONTINUE': {'ja': 'つづける', 'ko': '이어하기', 'en': 'Continue'},
      'UI_SETTINGS': {'ja': '設定', 'ko': '설정', 'en': 'Settings'},
      'UI_EXIT': {'ja': '終了', 'ko': '종료', 'en': 'Exit'},
      'UI_NEW_GAME': {'ja': 'ニューゲーム', 'ko': '새 게임', 'en': 'New Game'},
      'UI_LOAD_GAME': {'ja': 'ロード', 'ko': '불러오기', 'en': 'Load Game'},
      'UI_SAVE_GAME': {'ja': 'セーブ', 'ko': '저장하기', 'en': 'Save Game'},
      'GREETING': {
        'ja': 'こんにちは、{player_name}さん',
        'ko': '안녕하세요, {player_name}님',
        'en': 'Hello, {player_name}'
      },
    };
  }
}
