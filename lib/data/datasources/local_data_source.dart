import 'dart:convert';
import 'package:dev_quotes/data/dto/quote_dto.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalDataSource {
  Future<void> cacheUser(UserDto user);
  Future<UserDto?> getLastUser();
  Future<void> cacheLastQuote(QuoteDto quote);
  Future<QuoteDto?> getLastQuote();
  Future<void> cacheFavorites(List<String> ids);
  Future<List<String>> getFavorites();
}

class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences _sharedPreferences;

  LocalDataSourceImpl(this._sharedPreferences);

  static const String CACHED_USER = 'CACHED_USER';
  static const String CACHED_QUOTE = 'CACHED_QUOTE';
  static const String CACHED_FAVORITES = 'CACHED_FAVORITES';

  @override
  Future<void> cacheUser(UserDto user) {
    return _sharedPreferences.setString(CACHED_USER, json.encode(user.toJson()));
  }

  @override
  Future<UserDto?> getLastUser() async {
    final jsonString = _sharedPreferences.getString(CACHED_USER);
    if (jsonString != null) {
      return UserDto.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheLastQuote(QuoteDto quote) {
    return _sharedPreferences.setString(CACHED_QUOTE, json.encode(quote.toJson()));
  }

  @override
  Future<QuoteDto?> getLastQuote() async {
    final jsonString = _sharedPreferences.getString(CACHED_QUOTE);
    if (jsonString != null) {
      return QuoteDto.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheFavorites(List<String> ids) {
    return _sharedPreferences.setStringList(CACHED_FAVORITES, ids);
  }

  @override
  Future<List<String>> getFavorites() async {
    return _sharedPreferences.getStringList(CACHED_FAVORITES) ?? [];
  }
}
