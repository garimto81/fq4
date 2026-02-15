enum MapType {
  field,
  dungeon,
  town,
  boss,
}

class MapConnection {
  final String mapId;
  final String spawnPoint;

  MapConnection({
    required this.mapId,
    required this.spawnPoint,
  });
}

class EnemySpawnData {
  final String enemyId;
  final double x;
  final double y;
  final int count;

  EnemySpawnData({
    required this.enemyId,
    required this.x,
    required this.y,
    required this.count,
  });
}

class MapData {
  final String mapId;
  final String mapName;
  final int chapter;
  final double mapWidth;
  final double mapHeight;
  final String bgmPath;
  final MapType mapType;
  final Map<String, MapConnection> connections;
  final List<String> entryEvents;
  final List<EnemySpawnData> enemySpawns;
  final EnemySpawnData? bossSpawn;
  final Map<String, ({double x, double y})> spawnPoints;

  MapData({
    required this.mapId,
    required this.mapName,
    required this.chapter,
    this.mapWidth = 2560,
    this.mapHeight = 1600,
    required this.bgmPath,
    required this.mapType,
    this.connections = const {},
    this.entryEvents = const [],
    this.enemySpawns = const [],
    this.bossSpawn,
    this.spawnPoints = const {},
  });

  ({double width, double height}) getBounds() {
    return (width: mapWidth, height: mapHeight);
  }

  MapConnection? getConnection(String exitName) {
    return connections[exitName];
  }

  bool isBossMap() {
    return mapType == MapType.boss || bossSpawn != null;
  }

  bool isTown() {
    return mapType == MapType.town;
  }

  ({double x, double y})? getSpawnPoint(String name) {
    return spawnPoints[name];
  }
}
