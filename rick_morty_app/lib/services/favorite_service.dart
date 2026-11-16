import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  static const String _favIdsKey = 'favorite_ids';
  static const String _favCharactersKey = 'favorite_characters';
  final _favoritesStreamController = StreamController<void>.broadcast();

  Stream<void> get onFavoritesChanged => _favoritesStreamController.stream;

  /// Retrieve the list of favorite Character IDs saved in SharedPreferences.
  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final idStrings = prefs.getStringList(_favIdsKey) ?? [];
    return idStrings.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toSet();
  }

  /// Check whether a character is marked as favorite in SharedPreferences.
  Future<bool> isFavorite(int characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final idStrings = prefs.getStringList(_favIdsKey) ?? [];
    return idStrings.contains(characterId.toString());
  }

  /// Retrieve full list of favorite characters saved in SharedPreferences.
  Future<List<Character>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favCharactersKey) ?? [];
    return jsonList
        .map((s) {
          try {
            return Character.fromJson(json.decode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Character>()
        .toList();
  }

  /// Add a character to favorites in SharedPreferences (both ID list and Character data).
  Future<void> addFavorite(Character character) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update ID list
    final idStrings = (prefs.getStringList(_favIdsKey) ?? []).toSet();
    idStrings.add(character.id.toString());
    await prefs.setStringList(_favIdsKey, idStrings.toList());

    // 2. Update Character objects list
    final favorites = await getFavorites();
    if (!favorites.any((c) => c.id == character.id)) {
      favorites.add(character);
      final jsonList = favorites.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_favCharactersKey, jsonList);
    }

    _favoritesStreamController.add(null);
  }

  /// Remove a character from favorites in SharedPreferences.
  Future<void> removeFavorite(int characterId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update ID list
    final idStrings = (prefs.getStringList(_favIdsKey) ?? []).toSet();
    idStrings.remove(characterId.toString());
    await prefs.setStringList(_favIdsKey, idStrings.toList());

    // 2. Update Character objects list
    final favorites = await getFavorites();
    favorites.removeWhere((c) => c.id == characterId);
    final jsonList = favorites.map((c) => json.encode(c.toJson())).toList();
    await prefs.setStringList(_favCharactersKey, jsonList);

    _favoritesStreamController.add(null);
  }
}
