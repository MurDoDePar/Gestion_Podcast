class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  final Map<String, dynamic> _cache = {};

  bool hasKey(String key) {
    return _cache.containsKey(key);
  }

  dynamic read(String key) {
    return _cache[key];
  }

  void write(String key, dynamic data) {
    _cache[key] = data;
  }
}
