// Generic object pooling system for efficient object reuse
// Port from Godot GDScript object_pool.gd

class ObjectPool<T> {
  final T Function() factory;
  final void Function(T)? onAcquire;
  final void Function(T)? onRelease;

  final List<T> _pool = [];
  final List<T> _active = [];

  ObjectPool({
    required this.factory,
    this.onAcquire,
    this.onRelease,
    int initialSize = 10,
  }) {
    warmUp(initialSize);
  }

  void warmUp(int count) {
    for (int i = 0; i < count; i++) {
      _pool.add(factory());
    }
  }

  T acquire() {
    final obj = _pool.isNotEmpty ? _pool.removeLast() : factory();
    _active.add(obj);
    onAcquire?.call(obj);
    return obj;
  }

  void release(T obj) {
    if (_active.remove(obj)) {
      onRelease?.call(obj);
      _pool.add(obj);
    }
  }

  void releaseAll() {
    for (final obj in List.of(_active)) {
      release(obj);
    }
  }

  void clear() {
    _pool.clear();
    _active.clear();
  }

  int get activeCount => _active.length;
  int get poolSize => _pool.length;
  int get totalSize => _active.length + _pool.length;
}
