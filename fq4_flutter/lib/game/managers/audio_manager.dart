// AudioManager - Pure Dart audio state management
// Based on Godot audio_manager.gd
// Actual audio playback will be implemented with audioplayers package later

class AudioManager {
  static const int maxSfxChannels = 8;

  double masterVolume = 1.0;
  double bgmVolume = 0.8;
  double sfxVolume = 1.0;
  String currentBgm = '';
  bool isBgmPlaying = false;

  // Track what SFX are playing (channel -> sfx name)
  final Map<int, String> _activeSfx = {};
  int _nextSfxChannel = 0;

  // Callbacks for integration with audio playback layer
  Function(String trackName)? onBgmChanged;
  Function(String sfxName)? onSfxPlayed;
  Function(String busName, double value)? onVolumeChanged;

  void playBgm(String trackName) {
    if (currentBgm == trackName && isBgmPlaying) return;
    currentBgm = trackName;
    isBgmPlaying = true;
    onBgmChanged?.call(trackName);
  }

  void stopBgm() {
    isBgmPlaying = false;
    currentBgm = '';
  }

  void playSfx(String sfxName) {
    final channel = _getAvailableChannel();
    _activeSfx[channel] = sfxName;
    onSfxPlayed?.call(sfxName);
  }

  void stopSfx(int channel) {
    _activeSfx.remove(channel);
  }

  void stopAllSfx() {
    _activeSfx.clear();
  }

  int _getAvailableChannel() {
    // Find empty channel
    for (int i = 0; i < maxSfxChannels; i++) {
      if (!_activeSfx.containsKey(i)) return i;
    }
    // Reuse oldest
    final channel = _nextSfxChannel % maxSfxChannels;
    _nextSfxChannel++;
    return channel;
  }

  void setMasterVolume(double value) {
    masterVolume = value.clamp(0.0, 1.0);
    onVolumeChanged?.call('Master', masterVolume);
  }

  void setBgmVolume(double value) {
    bgmVolume = value.clamp(0.0, 1.0);
    onVolumeChanged?.call('BGM', bgmVolume);
  }

  void setSfxVolume(double value) {
    sfxVolume = value.clamp(0.0, 1.0);
    onVolumeChanged?.call('SFX', sfxVolume);
  }

  double getEffectiveBgmVolume() => bgmVolume * masterVolume;
  double getEffectiveSfxVolume() => sfxVolume * masterVolume;

  // Serialize for settings save
  Map<String, dynamic> serialize() => {
    'masterVolume': masterVolume,
    'bgmVolume': bgmVolume,
    'sfxVolume': sfxVolume,
  };

  void deserialize(Map<String, dynamic> data) {
    masterVolume = (data['masterVolume'] as num?)?.toDouble() ?? 1.0;
    bgmVolume = (data['bgmVolume'] as num?)?.toDouble() ?? 0.8;
    sfxVolume = (data['sfxVolume'] as num?)?.toDouble() ?? 1.0;
  }
}
