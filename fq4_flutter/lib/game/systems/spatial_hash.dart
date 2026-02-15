/// 공간 분할 해시맵 (100 유닛 최적화)
class SpatialHash<T> {
  SpatialHash({this.cellSize = 100});

  final int cellSize;
  final Map<int, Set<T>> _cells = {};
  final Map<T, _SpatialEntry> _entries = {};

  /// 유닛 삽입/갱신
  void updatePosition(T item, double x, double y) {
    final newKey = _hash(x, y);
    final existing = _entries[item];

    if (existing != null && existing.cellKey == newKey) return;

    // 이전 셀에서 제거
    if (existing != null) {
      _cells[existing.cellKey]?.remove(item);
    }

    // 새 셀에 삽입
    _cells.putIfAbsent(newKey, () => {}).add(item);
    _entries[item] = _SpatialEntry(cellKey: newKey, x: x, y: y);
  }

  /// 유닛 제거
  void remove(T item) {
    final entry = _entries.remove(item);
    if (entry != null) {
      _cells[entry.cellKey]?.remove(item);
    }
  }

  /// 범위 내 유닛 쿼리
  List<T> queryRange(double x, double y, double range) {
    final result = <T>[];
    final rangeSq = range * range;

    final minCellX = ((x - range) / cellSize).floor();
    final maxCellX = ((x + range) / cellSize).floor();
    final minCellY = ((y - range) / cellSize).floor();
    final maxCellY = ((y + range) / cellSize).floor();

    for (int cx = minCellX; cx <= maxCellX; cx++) {
      for (int cy = minCellY; cy <= maxCellY; cy++) {
        final key = _hashFromCell(cx, cy);
        final cell = _cells[key];
        if (cell == null) continue;

        for (final item in cell) {
          final entry = _entries[item];
          if (entry == null) continue;
          final dx = entry.x - x;
          final dy = entry.y - y;
          if (dx * dx + dy * dy <= rangeSq) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  /// 가장 가까운 유닛 찾기
  T? findNearest(double x, double y, double maxRange, List<T> candidates) {
    T? nearest;
    double nearestDistSq = maxRange * maxRange;

    for (final item in candidates) {
      final entry = _entries[item];
      if (entry == null) continue;
      final dx = entry.x - x;
      final dy = entry.y - y;
      final distSq = dx * dx + dy * dy;
      if (distSq < nearestDistSq) {
        nearestDistSq = distSq;
        nearest = item;
      }
    }

    return nearest;
  }

  /// 전체 클리어
  void clear() {
    _cells.clear();
    _entries.clear();
  }

  int _hash(double x, double y) {
    return _hashFromCell((x / cellSize).floor(), (y / cellSize).floor());
  }

  int _hashFromCell(int cx, int cy) {
    return cx * 73856093 ^ cy * 19349663;
  }
}

class _SpatialEntry {
  final int cellKey;
  final double x;
  final double y;

  const _SpatialEntry({
    required this.cellKey,
    required this.x,
    required this.y,
  });
}
