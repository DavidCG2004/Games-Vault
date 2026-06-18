import 'package:flutter/material.dart';
import 'package:games_vault/core/database/mongo_database.dart';
import 'package:games_vault/models/game_item.dart';

/// Provider para manejar la colección local de juegos (CRUD con MongoDB).
/// Incluye búsqueda y filtros por categoría/plataforma en memoria.
class CollectionProvider extends ChangeNotifier {
  final MongoDatabase _db = MongoDatabase();

  List<GameItem> _localGames = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ── Filtros en memoria (no requieren llamadas a DB) ───────────────────────
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  String _selectedPlatform = 'Todas';

  // ── Getters base ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalGames => _localGames.length;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedPlatform => _selectedPlatform;

  // ── Lista filtrada (derivada, no almacenada) ──────────────────────────────
  List<GameItem> get localGames {
    var games = _localGames;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      games = games
          .where((g) =>
              g.titulo.toLowerCase().contains(q) ||
              g.categoria.toLowerCase().contains(q) ||
              g.plataforma.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCategory != 'Todas') {
      games = games
          .where((g) =>
              g.categoria.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    if (_selectedPlatform != 'Todas') {
      games = games
          .where((g) =>
              g.plataforma.toLowerCase() == _selectedPlatform.toLowerCase())
          .toList();
    }

    return games;
  }

  /// Categorías únicas extraídas de la colección actual.
  List<String> get availableCategories {
    final cats = _localGames.map((g) => g.categoria).toSet().toList()..sort();
    return ['Todas', ...cats];
  }

  /// Plataformas únicas extraídas de la colección actual.
  List<String> get availablePlatforms {
    final plats = _localGames.map((g) => g.plataforma).toSet().toList()
      ..sort();
    return ['Todas', ...plats];
  }

  // ── Setters de filtro ─────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setPlatform(String platform) {
    if (_selectedPlatform == platform) return;
    _selectedPlatform = platform;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'Todas';
    _selectedPlatform = 'Todas';
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Cargar todos los juegos desde MongoDB.
  Future<void> fetchLocalGames() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _localGames = await _db.getGames();
    } catch (e) {
      _errorMessage = 'Error al cargar la colección: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agregar un juego a la colección.
  /// Verifica duplicados por título antes de insertar.
  Future<bool> addGame(GameItem game) async {
    try {
      final exists = _localGames.any(
        (g) => g.titulo.toLowerCase() == game.titulo.toLowerCase(),
      );
      if (exists) {
        _errorMessage = 'El juego "${game.titulo}" ya existe en tu colección.';
        notifyListeners();
        return false;
      }

      final success = await _db.insertGame(game);
      if (success) {
        _localGames.add(game);
        _errorMessage = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error al agregar juego: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualizar un juego existente.
  Future<bool> updateGame(GameItem game) async {
    try {
      final success = await _db.updateGame(game);
      if (success) {
        final index = _localGames.indexWhere((g) => g.id == game.id);
        if (index != -1) _localGames[index] = game;
        _errorMessage = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error al actualizar juego: $e';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar un juego por su ID.
  Future<bool> deleteGame(String id) async {
    try {
      final success = await _db.deleteGame(id);
      if (success) {
        _localGames.removeWhere((g) => g.id == id);
        _errorMessage = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error al eliminar juego: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}