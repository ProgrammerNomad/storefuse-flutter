class MemoryCacheEntry<T> {
  MemoryCacheEntry(this.value, this.expiresAt);
  final T value;
  final DateTime expiresAt;
}

/// Short TTL in-memory cache for public GET endpoints only.
class MemoryCache {
  final _store = <String, MemoryCacheEntry<dynamic>>{};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void set<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 2),
  }) {
    _store[key] = MemoryCacheEntry(value, DateTime.now().add(ttl));
  }

  void invalidate(String key) => _store.remove(key);

  void clear() => _store.clear();
}
