import 'package:uuid/uuid.dart';

/// Modelo unificado para juegos — compatible con MongoDB y RAWG API.
class GameItem {
  final String id;
  final String titulo;
  final String categoria;
  final String plataforma;
  final String imagen;
  final String descripcion;
  final String fuente;

  const GameItem({
    required this.id,
    required this.titulo,
    this.categoria = 'General',
    this.plataforma = 'Multiplataforma',
    this.imagen = '',
    this.descripcion = '',
    this.fuente = 'Manual',
  });

  /// Crear desde JSON de MongoDB.
  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          const Uuid().v4(),
      titulo: json['titulo'] as String? ?? 'Sin título',
      categoria: json['categoria'] as String? ?? 'General',
      plataforma: json['plataforma'] as String? ?? 'Multiplataforma',
      imagen: json['imagen'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fuente: json['fuente'] as String? ?? 'Manual',
    );
  }

  /// Mapear desde un resultado de la API de RAWG.
  factory GameItem.fromRawg(Map<String, dynamic> rawgData) {
    final genres = rawgData['genres'] as List<dynamic>?;
    final platforms = rawgData['platforms'] as List<dynamic>?;

    String plataformasStr = 'Multiplataforma';
    if (platforms != null && platforms.isNotEmpty) {
      plataformasStr = platforms
          .take(3)
          .map((p) => p['platform']?['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    return GameItem(
      id: const Uuid().v4(),
      titulo: rawgData['name'] as String? ?? 'Desconocido',
      categoria: (genres != null && genres.isNotEmpty)
          ? genres[0]['name'] as String? ?? 'General'
          : 'General',
      plataforma: plataformasStr,
      imagen: rawgData['background_image'] as String? ?? '',
      descripcion:
          'Rating: ${rawgData['rating'] ?? 'N/A'} — Lanzamiento: ${rawgData['released'] ?? 'N/A'}',
      fuente: 'RAWG API',
    );
  }

  /// Convertir a JSON para guardar en MongoDB.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'categoria': categoria,
      'plataforma': plataforma,
      'imagen': imagen,
      'descripcion': descripcion,
      'fuente': fuente,
    };
  }

  GameItem copyWith({
    String? id,
    String? titulo,
    String? categoria,
    String? plataforma,
    String? imagen,
    String? descripcion,
    String? fuente,
  }) {
    return GameItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      plataforma: plataforma ?? this.plataforma,
      imagen: imagen ?? this.imagen,
      descripcion: descripcion ?? this.descripcion,
      fuente: fuente ?? this.fuente,
    );
  }
}