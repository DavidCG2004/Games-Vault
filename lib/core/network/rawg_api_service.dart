import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Servicio para consumir la API de RAWG.io
class RawgApiService {
  static const String _apiKey = '471c36d73d614ad390e8abd7a788f96b';
  static const String _baseUrl = 'api.rawg.io';
  static const String _path = '/api/games';

  /// Obtener juegos paginados desde RAWG.
  /// Retorna un Map con 'results' (lista) y 'hasMore' (bool).
  ///
  /// Parámetros opcionales:
  /// - [search]     : filtra por nombre de juego.
  /// - [genre]      : filtra por género (ej: 'Action', 'RPG').
  /// - [platformId] : filtra por plataforma según ID de RAWG (ej: '4' = PC).
  Future<Map<String, dynamic>> getGames({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? genre,
    String? platformId,
  }) async {
    try {
      final params = <String, String>{
        'key': _apiKey,
        'page': '$page',
        'page_size': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (genre != null) 'genres': genre.toLowerCase(),
        'platforms': ?platformId,
      };

      final uri = Uri.https(_baseUrl, _path, params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final hasMore = data['next'] != null;

        log('[RAWG] Página $page cargada — ${results.length} resultados');
        return {'results': results, 'hasMore': hasMore};
      } else {
        log('[RAWG] Error HTTP: ${response.statusCode}');
        throw Exception('Error al cargar juegos: ${response.statusCode}');
      }
    } catch (e) {
      log('[RAWG] Error: $e');
      rethrow;
    }
  }
}