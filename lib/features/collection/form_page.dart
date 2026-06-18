import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:games_vault/core/theme/app_colors.dart';
import 'package:games_vault/core/services/image_service.dart';
import 'package:games_vault/models/game_item.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';

// ── Opciones de los dropdowns ─────────────────────────────────────────────────

const _kCategories = [
  'General',
  'Action',
  'RPG',
  'Strategy',
  'Adventure',
  'Shooter',
  'Puzzle',
  'Sports',
  'Racing',
  'Simulation',
  'Indie',
  'Fighting',
  'Horror',
];

const _kPlatforms = [
  'Multiplataforma',
  'PC',
  'PlayStation 5',
  'PlayStation 4',
  'Xbox Series S/X',
  'Xbox One',
  'Nintendo Switch',
  'iOS',
  'Android',
];

/// Formulario para crear o editar un juego.
class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;

  String _categoria = 'General';
  String _plataforma = 'Multiplataforma';
  String _imagenPath = '';   // ruta local o URL (juegos de RAWG)
  bool _isSaving = false;

  GameItem? _editingGame;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GameItem && !_isEditing) {
      _editingGame = args;
      _isEditing = true;
      _tituloCtrl.text = args.titulo;
      _descripcionCtrl.text = args.descripcion;
      _categoria = _kCategories.contains(args.categoria)
          ? args.categoria
          : 'General';
      _plataforma = _kPlatforms.contains(args.plataforma)
          ? args.plataforma
          : 'Multiplataforma';
      _imagenPath = args.imagen;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ── Imagen ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final path = await ImageService.instance.pickAndSave();
    if (path != null) setState(() => _imagenPath = path);
  }

  void _removeImage() => setState(() => _imagenPath = '');

  // ── Guardado ────────────────────────────────────────────────────────────────

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<CollectionProvider>();

    final game = GameItem(
      id: _editingGame?.id ?? const Uuid().v4(),
      titulo: _tituloCtrl.text.trim(),
      categoria: _categoria,
      plataforma: _plataforma,
      imagen: _imagenPath,
      descripcion: _descripcionCtrl.text.trim(),
      fuente: _editingGame?.fuente ?? 'Manual',
    );

    final success = _editingGame != null
        ? await provider.updateGame(game)
        : await provider.addGame(game);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingGame != null
                ? 'Juego actualizado exitosamente'
                : 'Juego creado exitosamente',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al guardar'),
        ),
      );
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar juego' : 'Nuevo juego'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sección: información ──────────────────────────────────────
              const _SectionLabel(label: 'Información'),
              const SizedBox(height: 12),

              // Título
              _FormField(
                controller: _tituloCtrl,
                label: 'Título',
                hint: 'Ej. The Witcher 3',
                icon: Icons.videogame_asset_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 12),

              // Dropdowns en fila
              Row(
                children: [
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Categoría',
                      icon: Icons.category_rounded,
                      value: _categoria,
                      items: _kCategories,
                      onChanged: (v) => setState(() => _categoria = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Plataforma',
                      icon: Icons.devices_rounded,
                      value: _plataforma,
                      items: _kPlatforms,
                      onChanged: (v) => setState(() => _plataforma = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Descripción
              _FormField(
                controller: _descripcionCtrl,
                label: 'Descripción',
                hint: '¿Por qué es tu favorito?',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              // ── Sección: imagen ───────────────────────────────────────────
              const _SectionLabel(label: 'Imagen'),
              const SizedBox(height: 12),

              _ImagePicker(
                imagePath: _imagenPath,
                onPick: _pickImage,
                onRemove: _removeImage,
              ),

              const SizedBox(height: 32),

              // ── Botón guardar ─────────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGame,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear juego'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets reutilizables del formulario
// ─────────────────────────────────────────────────────────────────────────────

/// Etiqueta de sección con trazo visual.
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 2,
      ),
    );
  }
}

/// Campo de texto estilizado.
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Dropdown estilizado consistente con el tema monocromático.
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(
        Icons.expand_more_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      dropdownColor: AppColors.background,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Widget de selección y previsualización de imagen.
class _ImagePicker extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  bool get _hasImage => imagePath.isNotEmpty;
  bool get _isLocal => ImageService.instance.isLocalPath(imagePath);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Preview o placeholder ───────────────────────────────────────
        GestureDetector(
          onTap: onPick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasImage ? AppColors.border : AppColors.divider,
                width: _hasImage ? 1 : 1,
                // Borde punteado simulado con strokeAlign
              ),
            ),
            child: _hasImage ? _buildPreview() : _buildPlaceholder(),
          ),
        ),

        // ── Botones ────────────────────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label: Text(
                  _hasImage ? 'Cambiar imagen' : 'Seleccionar imagen',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_hasImage) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: _isLocal
          ? Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              errorBuilder: (_, _, _) => _buildBrokenImage(),
            )
          : Image.network(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textTertiary,
                        strokeWidth: 1.5,
                      ),
                    ),
              errorBuilder: (_, _, _) => _buildBrokenImage(),
            ),
    );
  }

  Widget _buildPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 40,
          color: AppColors.textTertiary,
        ),
        SizedBox(height: 10),
        Text(
          'Toca para seleccionar una imagen',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'JPG, PNG — desde tu galería',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBrokenImage() {
    return const Center(
      child: Icon(
        Icons.broken_image_rounded,
        size: 36,
        color: AppColors.textTertiary,
      ),
    );
  }
}