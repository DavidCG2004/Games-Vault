import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:games_vault/core/theme/app_colors.dart';
import 'package:games_vault/core/services/image_service.dart';
import 'package:games_vault/models/game_item.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';

/// Pantalla de listado de la colección local con búsqueda, filtros y Pull-to-Refresh.
class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(
      () => context.read<CollectionProvider>().fetchLocalGames(),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<CollectionProvider>().setSearchQuery(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CollectionProvider>().setSearchQuery('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección'),
      ),
      body: Column(
        children: [
          // ── Header fijo: búsqueda + filtros ──────────────────────────────
          _SearchAndFilters(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          const Divider(height: 1),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: Consumer<CollectionProvider>(
              builder: (context, provider, _) {
                // Carga inicial
                if (provider.isLoading && provider.totalGames == 0) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  );
                }

                // Colección vacía (sin filtros aplicados)
                if (provider.totalGames == 0) {
                  return _EmptyCollection(
                    onExplore: () =>
                        Navigator.pushNamed(context, '/explorer'),
                  );
                }

                // Sin resultados para los filtros actuales
                if (provider.localGames.isEmpty) {
                  return _EmptyFiltered(
                    onClear: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.card,
                  onRefresh: () => provider.fetchLocalGames(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: provider.localGames.length,
                    itemBuilder: (context, index) {
                      final game = provider.localGames[index];
                      return _GameListTile(
                        game: game,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: game,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/form');
          if (result == true && context.mounted) {
            context.read<CollectionProvider>().fetchLocalGames();
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: buscador + chips dinámicos
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAndFilters extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _SearchAndFilters({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buscador ───────────────────────────────────────────────────
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Buscar en tu colección...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (_, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onClear,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Filtro por categoría ────────────────────────────────────────
          const _FilterLabel(label: 'Categoría'),
          const SizedBox(height: 6),
          const _CategoryFilterRow(),
          const SizedBox(height: 10),

          // ── Filtro por plataforma ────────────────────────────────────────
          const _FilterLabel(label: 'Plataforma'),
          const SizedBox(height: 6),
          const _PlatformFilterRow(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String label;
  const _FilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final categories = provider.availableCategories;

    if (categories.length <= 1) {
      return const SizedBox(
        height: 30,
        child: Text(
          'Sin categorías aún',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _FilterChip(
            label: cat,
            isSelected: provider.selectedCategory == cat,
            onTap: () => provider.setCategory(cat),
          );
        },
      ),
    );
  }
}

class _PlatformFilterRow extends StatelessWidget {
  const _PlatformFilterRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final platforms = provider.availablePlatforms;

    if (platforms.length <= 1) {
      return const SizedBox(
        height: 30,
        child: Text(
          'Sin plataformas aún',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final plat = platforms[index];
          return _FilterChip(
            label: plat,
            isSelected: provider.selectedPlatform == plat,
            onTap: () => provider.setPlatform(plat),
          );
        },
      ),
    );
  }
}

/// Chip de filtro monocromático — seleccionado = fondo negro / texto blanco.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color:
                isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vacíos
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCollection extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyCollection({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videogame_asset_off_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu colección está vacía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agrega juegos manualmente o explora el catálogo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onExplore,
              child: const Text('Explorar catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyFiltered({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.filter_list_off_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ningún juego coincide con los filtros activos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de juego
// ─────────────────────────────────────────────────────────────────────────────

class _GameListTile extends StatelessWidget {
  final GameItem game;
  final VoidCallback onTap;

  const _GameListTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.divider,
          highlightColor: AppColors.surface,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                // ── Imagen (local o URL) ──────────────────────────────────
                Hero(
                  tag: 'game_image_${game.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _TileImage(imagePath: game.imagen),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Info ──────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${game.categoria} · ${game.plataforma}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Imagen del tile — maneja ruta local, URL remota y ausencia de imagen.
class _TileImage extends StatelessWidget {
  final String imagePath;
  const _TileImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    const size = 56.0;

    if (imagePath.isEmpty) {
      return _placeholder(size, Icons.games_rounded);
    }

    if (ImageService.instance.isLocalPath(imagePath)) {
      return Image.file(
        File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _placeholder(size, Icons.broken_image_rounded),
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(size, Icons.image_rounded),
      errorWidget: (_, _, _) =>
          _placeholder(size, Icons.broken_image_rounded),
    );
  }

  Widget _placeholder(double size, IconData icon) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: Icon(icon, color: AppColors.textTertiary, size: 22),
    );
  }
}