// SaveSystem: Handles save/load operations for game state
//
// 3 manual save slots + 1 auto-save slot (slot 0)
// In-memory store for now (file I/O will be added with path_provider later)

class SaveSlotInfo {
  final int slot;
  final bool exists;
  final int version;
  final String timestamp;
  final int playTime;
  final int chapter;
  final int playerLevel;
  final bool corrupted;

  const SaveSlotInfo({
    required this.slot,
    required this.exists,
    this.version = 0,
    this.timestamp = '',
    this.playTime = 0,
    this.chapter = 1,
    this.playerLevel = 1,
    this.corrupted = false,
  });
}

class SaveSystem {
  static const int saveVersion = 1;
  static const int autoSaveSlot = 0;
  static const int maxSlots = 3;

  // In-memory save data store (real file I/O will be added later)
  final Map<int, Map<String, dynamic>> _saveStore = {};

  Function(int slot, bool success)? onSaveCompleted;
  Function(int slot, bool success)? onLoadCompleted;
  Function()? onAutoSaveTriggered;

  // Save game to slot
  bool saveGame(
    int slot, {
    required Map<String, dynamic> gameState,
    required List<Map<String, dynamic>> playerUnits,
    required Map<String, dynamic> inventory,
    Map<String, dynamic>? achievements,
  }) {
    if (slot < 0 || slot > maxSlots) {
      onSaveCompleted?.call(slot, false);
      return false;
    }

    final timestamp = DateTime.now().toIso8601String();
    final saveData = {
      'version': saveVersion,
      'timestamp': timestamp,
      'game_state': gameState,
      'player_units': playerUnits,
      'inventory': inventory,
      'achievements': achievements ?? {},
    };

    _saveStore[slot] = saveData;
    onSaveCompleted?.call(slot, true);
    return true;
  }

  // Load game from slot
  Map<String, dynamic>? loadGame(int slot) {
    if (slot < 0 || slot > maxSlots) {
      onLoadCompleted?.call(slot, false);
      return null;
    }

    if (!_saveStore.containsKey(slot)) {
      onLoadCompleted?.call(slot, false);
      return null;
    }

    final saveData = _saveStore[slot];
    onLoadCompleted?.call(slot, true);
    return saveData;
  }

  // Auto-save
  bool autoSave({
    required Map<String, dynamic> gameState,
    required List<Map<String, dynamic>> playerUnits,
    required Map<String, dynamic> inventory,
    Map<String, dynamic>? achievements,
  }) {
    onAutoSaveTriggered?.call();
    return saveGame(
      autoSaveSlot,
      gameState: gameState,
      playerUnits: playerUnits,
      inventory: inventory,
      achievements: achievements,
    );
  }

  // Get save slot info
  SaveSlotInfo getSlotInfo(int slot) {
    if (!_saveStore.containsKey(slot)) {
      return SaveSlotInfo(slot: slot, exists: false);
    }

    final saveData = _saveStore[slot];
    if (saveData == null) {
      return SaveSlotInfo(slot: slot, exists: false, corrupted: true);
    }

    try {
      final gameState = saveData['game_state'] as Map<String, dynamic>? ?? {};
      final playerUnits = saveData['player_units'] as List? ?? [];

      int playerLevel = 1;
      if (playerUnits.isNotEmpty) {
        final firstUnit = playerUnits[0] as Map<String, dynamic>;
        final exp = firstUnit['experience'] as Map<String, dynamic>?;
        playerLevel = exp?['current_level'] as int? ?? 1;
      }

      return SaveSlotInfo(
        slot: slot,
        exists: true,
        version: saveData['version'] as int? ?? 0,
        timestamp: saveData['timestamp'] as String? ?? '',
        playTime: gameState['play_time'] as int? ?? 0,
        chapter: gameState['chapter'] as int? ?? 1,
        playerLevel: playerLevel,
        corrupted: false,
      );
    } catch (e) {
      return SaveSlotInfo(slot: slot, exists: true, corrupted: true);
    }
  }

  // Get all slots info
  List<SaveSlotInfo> getAllSlotsInfo() {
    final result = <SaveSlotInfo>[];
    for (int slot = autoSaveSlot; slot <= maxSlots; slot++) {
      result.add(getSlotInfo(slot));
    }
    return result;
  }

  // Delete save (slot 0 auto-save cannot be deleted)
  bool deleteSave(int slot) {
    if (slot < 1 || slot > maxSlots) {
      return false;
    }

    if (_saveStore.containsKey(slot)) {
      _saveStore.remove(slot);
      return true;
    }
    return false;
  }

  // Check if save exists
  bool hasSaveData(int slot) {
    return _saveStore.containsKey(slot);
  }
}
