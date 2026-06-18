import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Servicio para seleccionar y persistir imágenes localmente.
///
/// Flujo:
/// 1. El usuario selecciona una imagen con [pickImage].
/// 2. La imagen se copia al directorio de documentos de la app.
/// 3. Se devuelve la ruta absoluta local para guardar en MongoDB.
/// 4. En la UI se carga con [Image.file] usando esa ruta.
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final _picker = ImagePicker();

  /// Abre el selector de imágenes y copia la imagen elegida
  /// al directorio interno de la app.
  ///
  /// Retorna la ruta local persistida, o `null` si el usuario cancela.
  Future<String?> pickAndSave() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    return _copyToAppDir(File(picked.path));
  }

  /// Copia el archivo al directorio de documentos de la app,
  /// con un nombre único basado en timestamp.
  Future<String> _copyToAppDir(File source) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final gamesDir = Directory(p.join(docsDir.path, 'game_images'));
    if (!await gamesDir.exists()) await gamesDir.create(recursive: true);

    final ext = p.extension(source.path);
    final filename = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(gamesDir.path, filename));

    await source.copy(dest.path);
    return dest.path;
  }

  /// Elimina una imagen del almacenamiento local si existe.
  /// Llamar al eliminar un juego para no acumular archivos huérfanos.
  Future<void> deleteIfLocal(String path) async {
    if (path.isEmpty) return;
    // Solo borrar si es ruta local (no URL http)
    if (path.startsWith('http')) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Determina si una ruta es local (file system) o remota (URL).
  bool isLocalPath(String path) =>
      path.isNotEmpty && !path.startsWith('http');
}