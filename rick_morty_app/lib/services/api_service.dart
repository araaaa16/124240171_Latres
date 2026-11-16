import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character_model.dart';
import '../models/episode_model.dart';

class PageInfo {
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  const PageInfo({
    required this.count,
    required this.pages,
    this.next,
    this.prev,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      count: json['count'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      next: json['next'] as String?,
      prev: json['prev'] as String?,
    );
  }
}

class CharacterResponse {
  final PageInfo info;
  final List<Character> results;

  const CharacterResponse({required this.info, required this.results});

  factory CharacterResponse.fromJson(Map<String, dynamic> json) {
    final infoMap = json['info'] as Map<String, dynamic>? ?? {};
    final resultsList = (json['results'] as List<dynamic>?) ?? [];
    return CharacterResponse(
      info: PageInfo.fromJson(infoMap),
      results: resultsList
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EpisodeResponse {
  final PageInfo info;
  final List<Episode> results;

  const EpisodeResponse({required this.info, required this.results});

  factory EpisodeResponse.fromJson(Map<String, dynamic> json) {
    final infoMap = json['info'] as Map<String, dynamic>? ?? {};
    final resultsList = (json['results'] as List<dynamic>?) ?? [];
    return EpisodeResponse(
      info: PageInfo.fromJson(infoMap),
      results: resultsList
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiService {
  static const String _baseUrl = 'https://rickandmortyapi.com/api';

  Future<CharacterResponse> getCharacters({
    int page = 1,
    String? status,
    String? name,
  }) async {
    final queryParams = <String, String>{'page': page.toString()};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (name != null && name.isNotEmpty) queryParams['name'] = name;

    final uri =
        Uri.parse('$_baseUrl/character').replace(queryParameters: queryParams);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return CharacterResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return CharacterResponse(
          info: const PageInfo(count: 0, pages: 0, next: null, prev: null),
          results: [],
        );
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Character> getCharacterById(int id) async {
    final uri = Uri.parse('$_baseUrl/character/$id');
    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return Character.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load character: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<EpisodeResponse> getEpisodes({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/episode').replace(
      queryParameters: {'page': page.toString()},
    );
    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return EpisodeResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load episodes: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
