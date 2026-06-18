import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:games_vault/core/theme/app_colors.dart';
import 'package:games_vault/core/services/image_service.dart';
import 'package:games_vault/models/game_item.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';

/// Pantalla de detalle de un juego con Hero animation.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = ModalRoute.of(context)!.settings.arguments as GameItem;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar con imagen ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: _CircleAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _CircleAction(
                icon: Icons.edit_rounded,
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/form',
                    arguments: game,
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              _CircleAction(
                icon: Icons.delete_outline_rounded,
                onTap: () => _confirmDelete(context, game),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'game_image_${game.id}',
                child: _GameImage(imagePath: game.imagen),
              ),
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + badge fuente
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          game.titulo,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FuenteBadge(fuente: game.fuente),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Info rows
                  _InfoRow(
                    icon: Icons.category_rounded,
                    label: 'Categoría',
                    value: game.categoria,
                  ),
                  _InfoRow(
                    icon: Icons.devices_rounded,
                    label: 'Plataforma',
                    value: game.plataforma,
                  ),

                  // Descripción
                  if (game.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                      'DESCRIPCIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      game.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GameItem game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar juego'),
        content: Text('¿Seguro que deseas eliminar "${game.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Limpiar imagen local si existe
              await ImageService.instance.deleteIfLocal(game.imagen);
              if (!ctx.mounted) return;
              final success = await ctx
                  .read<CollectionProvider>()
                  .deleteGame(game.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Juego eliminado')),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Botón circular semitransparente para la AppBar.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 18, color: AppColors.text),
      ),
    );
  }
}

/// Imagen del juego — maneja ruta local y URL remota.
class _GameImage extends StatelessWidget {
  final String imagePath;
  const _GameImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) return _placeholder();

    if (ImageService.instance.isLocalPath(imagePath)) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, _) => _placeholder(loading: true),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(
                color: AppColors.textTertiary,
                strokeWidth: 1.5,
              )
            : const Icon(
                Icons.games_rounded,
                color: AppColors.textTertiary,
                size: 56,
              ),
      ),
    );
  }
}

/// Badge de fuente monocromático.
class _FuenteBadge extends StatelessWidget {
  final String fuente;
  const _FuenteBadge({required this.fuente});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        fuente,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Fila de información con ícono, etiqueta y valor.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}