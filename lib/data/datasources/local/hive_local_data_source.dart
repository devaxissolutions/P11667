import 'package:dev_quotes/core/utils/logger.dart';
import 'package:dev_quotes/data/dto/quote_dto.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:hive/hive.dart';

/// Comprehensive local data source using Hive for offline-first architecture
class HiveLocalDataSource {
  static const String _quotesBoxName = 'quotes';
  static const String _usersBoxName = 'users';
  static const String _favoritesBoxName = 'favorites';
  static const String _settingsBoxName = 'settings';
  static const String _metadataBoxName = 'metadata';

  Box<Map>? _quotesBox;
  Box<Map>? _usersBox;
  Box<List>? _favoritesBox;
  Box<dynamic>? _settingsBox;
  Box<dynamic>? _metadataBox;

  /// Initialize all Hive boxes
  Future<void> initialize() async {
    _quotesBox = await Hive.openBox<Map>(_quotesBoxName);
    _usersBox = await Hive.openBox<Map>(_usersBoxName);
    _favoritesBox = await Hive.openBox<List>(_favoritesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);
    
    Logger.d('HiveLocalDataSource initialized');
  }

  // ==================== QUOTES ====================

  /// Cache a single quote
  Future<void> cacheQuote(QuoteDto quote) async {
    await _quotesBox?.put(quote.id, quote.toJson());
  }

  /// Cache multiple quotes
  Future<void> cacheQuotes(List<QuoteDto> quotes) async {
    final Map<String, Map> quotesMap = {
      for (final quote in quotes) quote.id: quote.toJson()
    };
    await _quotesBox?.putAll(quotesMap);
    Logger.d('Cached ${quotes.length} quotes');
  }

  /// Get a single cached quote
  QuoteDto? getCachedQuote(String id) {
    final data = _quotesBox?.get(id);
    if (data != null) {
      return QuoteDto.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Get all cached quotes
  List<QuoteDto> getAllCachedQuotes() {
    final quotes = _quotesBox?.values.map((data) {
      return QuoteDto.fromJson(Map<String, dynamic>.from(data));
    }).toList();
    return quotes ?? [];
  }

  /// Get quotes by category
  List<QuoteDto> getCachedQuotesByCategory(String category) {
    final allQuotes = getAllCachedQuotes();
    return allQuotes.where((q) => q.category == category).toList();
  }

  /// Search cached quotes
  List<QuoteDto> searchCachedQuotes(String query) {
    final lowerQuery = query.toLowerCase();
    final allQuotes = getAllCachedQuotes();
    return allQuotes.where((q) {
      return q.text.toLowerCase().contains(lowerQuery) ||
             q.author.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get user's cached quotes
  List<QuoteDto> getCachedUserQuotes(String userId) {
    final allQuotes = getAllCachedQuotes();
    return allQuotes.where((q) => q.userId == userId).toList();
  }

  /// Delete a cached quote
  Future<void> deleteCachedQuote(String id) async {
    await _quotesBox?.delete(id);
  }

  /// Clear all cached quotes
  Future<void> clearCachedQuotes() async {
    await _quotesBox?.clear();
  }

  // ==================== USERS ====================

  /// Cache user data
  Future<void> cacheUser(UserDto user) async {
    await _usersBox?.put(user.id, user.toJson());
  }

  /// Get cached user
  UserDto? getCachedUser(String id) {
    final data = _usersBox?.get(id);
    if (data != null) {
      return UserDto.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Get current cached user (assumes single user app)
  UserDto? getCurrentCachedUser() {
    final users = _usersBox?.values.toList();
    if (users != null && users.isNotEmpty) {
      return UserDto.fromJson(Map<String, dynamic>.from(users.first));
    }
    return null;
  }

  /// Delete cached user
  Future<void> deleteCachedUser(String id) async {
    await _usersBox?.delete(id);
  }

  /// Clear all cached users
  Future<void> clearCachedUsers() async {
    await _usersBox?.clear();
  }

  // ==================== FAVORITES ====================

  /// Get cached favorites for a user
  List<String> getCachedFavorites(String userId) {
    final favorites = _favoritesBox?.get(userId);
    if (favorites != null) {
      return List<String>.from(favorites);
    }
    return [];
  }

  /// Add a favorite
  Future<void> addFavorite(String userId, String quoteId) async {
    final favorites = getCachedFavorites(userId);
    if (!favorites.contains(quoteId)) {
      favorites.add(quoteId);
      await _favoritesBox?.put(userId, favorites);
    }
  }

  /// Remove a favorite
  Future<void> removeFavorite(String userId, String quoteId) async {
    final favorites = getCachedFavorites(userId);
    favorites.remove(quoteId);
    await _favoritesBox?.put(userId, favorites);
  }

  /// Check if a quote is favorited
  bool isFavorite(String userId, String quoteId) {
    final favorites = getCachedFavorites(userId);
    return favorites.contains(quoteId);
  }

  /// Get favorite quotes as QuoteDto objects
  List<QuoteDto> getCachedFavoriteQuotes(String userId) {
    final favoriteIds = getCachedFavorites(userId);
    final favoriteQuotes = <QuoteDto>[];
    
    for (final id in favoriteIds) {
      final quote = getCachedQuote(id);
      if (quote != null) {
        favoriteQuotes.add(quote);
      }
    }
    
    return favoriteQuotes;
  }

  /// Clear favorites for a user
  Future<void> clearFavorites(String userId) async {
    await _favoritesBox?.delete(userId);
  }

  // ==================== SETTINGS ====================

  /// Save a setting value
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _settingsBox?.get(key);
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  // ==================== METADATA ====================

  /// Save last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _metadataBox?.put('last_sync', timestamp.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTimestamp() {
    final timestampStr = _metadataBox?.get('last_sync') as String?;
    if (timestampStr != null) {
      return DateTime.tryParse(timestampStr);
    }
    return null;
  }

  /// Save last quotes fetch timestamp
  Future<void> setLastQuotesFetch(DateTime timestamp) async {
    await _metadataBox?.put('last_quotes_fetch', timestamp.toIso8601String());
  }

  /// Get last quotes fetch timestamp
  DateTime? getLastQuotesFetch() {
    final timestampStr = _metadataBox?.get('last_quotes_fetch') as String?;
    if (timestampStr != null) {
      return DateTime.tryParse(timestampStr);
    }
    return null;
  }

  /// Check if data is stale (older than specified duration)
  bool isDataStale(Duration maxAge) {
    final lastFetch = getLastQuotesFetch();
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > maxAge;
  }

  /// Save app version for migration checks
  Future<void> setAppVersion(String version) async {
    await _metadataBox?.put('app_version', version);
  }

  /// Get saved app version
  String? getAppVersion() {
    return _metadataBox?.get('app_version') as String?;
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all cached data (except settings)
  Future<void> clearAllCache() async {
    await _quotesBox?.clear();
    await _usersBox?.clear();
    await _favoritesBox?.clear();
    await _metadataBox?.clear();
    Logger.d('Cleared all cached data');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'quotes': _quotesBox?.length ?? 0,
      'users': _usersBox?.length ?? 0,
      'favorites_entries': _favoritesBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
    };
  }

  /// Close all boxes
  Future<void> close() async {
    await _quotesBox?.close();
    await _usersBox?.close();
    await _favoritesBox?.close();
    await _settingsBox?.close();
    await _metadataBox?.close();
  }
}
