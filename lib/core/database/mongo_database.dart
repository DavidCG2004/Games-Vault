import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:games_vault/models/game_item.dart';

/// Servicio Singleton para la conexión a MongoDB.
///
/// ⚠️ NOTA: En producción NO se debe conectar directamente a la base de datos
/// desde el cliente por motivos de seguridad. Esta implementación es válida
/// para entornos de desarrollo y talleres académicos.
class MongoDatabase {
  static final MongoDatabase _instance = MongoDatabase._internal();
  factory MongoDatabase() => _instance;
  MongoDatabase._internal();

  static const String _connectionUri = 'mongodb+srv://alexandergarcia215:dNeSmI6IXCCgcDk7@cluster0.8kyjsgt.mongodb.net/?appName=Cluster0';
  static const String _collectionName = 'games';

  Db? _db;
  DbCollection? _collection;

  bool get isConnected => _db != null && _db!.isConnected;

  /// Abrir conexión a MongoDB, o reabrirla si se perdió (ej. tras
  /// que el sistema suspendiera la app en background).
  ///
  /// Es seguro llamarlo múltiples veces: si ya hay una conexión activa,
  /// no hace nada. Si la conexión existe pero está caída, la limpia y
  /// abre una nueva.
  Future<void> connect() async {
    // Ya conectado y saludable — no hacer nada.
    if (isConnected) {
      log('[MongoDB] Ya conectado, se omite reconexión.');
      return;
    }

    // Conexión previa muerta — limpiar antes de abrir una nueva.
    if (_db != null) {
      try {
        await _db!.close();
      } catch (_) {
        // Ignorar errores al cerrar una conexión ya rota.
      }
      _db = null;
      _collection = null;
    }

    try {
      _db = await Db.create(_connectionUri);
      await _db!.open();
      _collection = _db!.collection(_collectionName);
      log('[MongoDB] Conexión exitosa a $_connectionUri');
    } catch (e) {
      log('[MongoDB] Error al conectar: $e');
      _db = null;
      _collection = null;
      rethrow;
    }
  }

  /// Garantiza que haya una conexión activa antes de ejecutar una query.
  /// Se usa internamente en cada operación CRUD para auto-recuperarse
  /// de conexiones caídas sin que el llamador tenga que preocuparse.
  Future<void> _ensureConnected() async {
    if (!isConnected) {
      log('[MongoDB] Conexión perdida, reconectando...');
      await connect();
    }
  }

  /// Cerrar la conexión.
  Future<void> close() async {
    await _db?.close();
    log('[MongoDB] Conexión cerrada.');
  }

  /// Obtener todos los juegos de la colección.
  Future<List<GameItem>> getGames() async {
    try {
      await _ensureConnected();
      final results = await _collection!.find().toList();
      return results.map((doc) => GameItem.fromJson(doc)).toList();
    } catch (e) {
      log('[MongoDB] Error al obtener juegos: $e');
      return [];
    }
  }

  /// Insertar un nuevo juego.
  Future<bool> insertGame(GameItem game) async {
    try {
      await _ensureConnected();
      await _collection!.insertOne(game.toJson());
      log('[MongoDB] Juego insertado: ${game.titulo}');
      return true;
    } catch (e) {
      log('[MongoDB] Error al insertar: $e');
      return false;
    }
  }

  /// Actualizar un juego existente por su ID.
  Future<bool> updateGame(GameItem game) async {
    try {
      await _ensureConnected();
      await _collection!.replaceOne(
        where.eq('_id', game.id),
        game.toJson(),
      );
      log('[MongoDB] Juego actualizado: ${game.titulo}');
      return true;
    } catch (e) {
      log('[MongoDB] Error al actualizar: $e');
      return false;
    }
  }

  /// Eliminar un juego por su ID.
  Future<bool> deleteGame(String id) async {
    try {
      await _ensureConnected();
      await _collection!.deleteOne(where.eq('_id', id));
      log('[MongoDB] Juego eliminado: $id');
      return true;
    } catch (e) {
      log('[MongoDB] Error al eliminar: $e');
      return false;
    }
  }

  /// Buscar un juego por título (para evitar duplicados).
  Future<GameItem?> findByTitle(String titulo) async {
    try {
      await _ensureConnected();
      final doc = await _collection!.findOne(where.eq('titulo', titulo));
      return doc != null ? GameItem.fromJson(doc) : null;
    } catch (e) {
      log('[MongoDB] Error al buscar por título: $e');
      return null;
    }
  }
}
