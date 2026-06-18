import 'package:flutter/material.dart';
import 'package:games_vault/core/network/rawg_api_service.dart';


class ExplorerFilters {
  static const List<String> genres = [
    'Todos', 'Action', 'RPG', 'Strategy', 'Adventure',
    'Shooter', 'Puzzle', 'Sports', 'Racing', 'Simulation', 'Indie',
  ];

  /// Slugs exactos que acepta la RAWG API.
  static const Map<String, String> genreSlugs = {
    'Action':     'action',
    'RPG':        'role-playing-games-rpg',
    'Strategy':   'strategy',
    'Adventure':  'adventure',
    'Shooter':    'shooter',
    'Puzzle':     'puzzle',
    'Sports':     'sports',
    'Racing':     'racing',
    'Simulation': 'simulation',
    'Indie':      'indie',
  };

  static const List<String> platforms = [
    'Todas', 'PC', 'PlayStation 5', 'Xbox Series S/X',
    'Nintendo Switch', 'iOS', 'Android',
  ];

  static const Map<String, String> platformIds = {
    'PC':               '4',
    'PlayStation 5':    '187',
    'Xbox Series S/X':  '186',
    'Nintendo Switch':  '7',
    'iOS':              '3',
    'Android':          '21',
  };
}

/// Provider para el explorador de juegos vía RAWG API.
/// Soporta búsqueda por texto, filtros de género/plataforma e infinite scrolling.
class ApiExplorerProvider extends ChangeNotifier {
  final RawgApiService _apiService = RawgApiService();

  List<Map<String, dynamic>> _rawgGames = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  // ── Filtros activos ───────────────────────────────────────────────────────
  String _searchQuery = '';
  String _selectedGenre = 'Todos';
  String _selectedPlatform = 'Todas';

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get rawgGames => _rawgGames;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;
  String get selectedPlatform => _selectedPlatform;

  // ── Filtros ───────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _resetAndLoad();
  }

  void setGenre(String genre) {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    _resetAndLoad();
  }

  void setPlatform(String platform) {
    if (_selectedPlatform == platform) return;
    _selectedPlatform = platform;
    _resetAndLoad();
  }

  // ── Carga de datos ────────────────────────────────────────────────────────

  /// Reinicia la lista y carga desde la primera página con los filtros actuales.
  Future<void> _resetAndLoad() async {
    _rawgGames = [];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
    await loadMoreGames();
  }

  /// Cargar más juegos (paginación con filtros activos).
  Future<void> loadMoreGames() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final genre = _selectedGenre == 'Todos'? null: ExplorerFilters.genreSlugs[_selectedGenre];
      final platformId = _selectedPlatform == 'Todas'
          ? null
          : ExplorerFilters.platformIds[_selectedPlatform];

      final data = await _apiService.getGames(
        page: _currentPage,
        pageSize: 20,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        genre: genre,
        platformId: platformId,
      );

      final results = (data['results'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      _rawgGames.addAll(results);
      _hasMore = data['hasMore'] as bool;
      _currentPage++;
    } catch (e) {
      _errorMessage = 'Error al cargar juegos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reiniciar filtros y lista completa.
  Future<void> refresh() async {
    _searchQuery = '';
    _selectedGenre = 'Todos';
    _selectedPlatform = 'Todas';
    await _resetAndLoad();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}