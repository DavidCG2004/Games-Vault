import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:games_vault/core/theme/app_colors.dart';
import 'package:games_vault/models/game_item.dart';
import 'package:games_vault/features/api_explorer/providers/api_explorer_provider.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';

/// Pantalla de exploración de juegos vía RAWG API con búsqueda, filtros e infinite scrolling.
class ApiExplorerPage extends StatefulWidget {
  const ApiExplorerPage({super.key});

  @override
  State<ApiExplorerPage> createState() => _ApiExplorerPageState();
}

class _ApiExplorerPageState extends State<ApiExplorerPage> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();

    Future.microtask(
      () => context.read<ApiExplorerProvider>().loadMoreGames(),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ApiExplorerProvider>().loadMoreGames();
    }
  }

  /// Debounce de 450ms para no disparar búsquedas en cada tecla.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<ApiExplorerProvider>().setSearchQuery(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ApiExplorerProvider>().setSearchQuery('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reiniciar',
            onPressed: () {
              _searchController.clear();
              context.read<ApiExplorerProvider>().refresh();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Header fijo: búsqueda + filtros ────────────────────────────
          _SearchAndFilters(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          const Divider(height: 1),

          // ── Lista de resultados ─────────────────────────────────────────
          Expanded(
            child: Consumer<ApiExplorerProvider>(
              builder: (context, provider, _) {
                // Estado de error (sin resultados)
                if (provider.errorMessage != null &&
                    provider.rawgGames.isEmpty) {
                  return _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: () => provider.refresh(),
                  );
                }

                // Carga inicial
                if (provider.isLoading && provider.rawgGames.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  );
                }

                // Sin resultados
                if (!provider.isLoading && provider.rawgGames.isEmpty) {
                  return _EmptyState(
                    query: provider.searchQuery,
                    onClear: () {
                      _searchController.clear();
                      provider.refresh();
                    },
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount:
                      provider.rawgGames.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.rawgGames.length) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    final rawgItem = provider.rawgGames[index];
                    return _RawgGameCard(
                      rawgItem: rawgItem,
                      onSave: () => _saveToCollection(rawgItem),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToCollection(Map<String, dynamic> rawgItem) async {
    final gameToSave = GameItem.fromRawg(rawgItem);
    final provider = context.read<CollectionProvider>();
    final success = await provider.addGame(gameToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '"${gameToSave.titulo}" guardado en tu colección'
                : provider.errorMessage ?? 'No se pudo guardar el juego',
          ),
        ),
      );
      if (!success) provider.clearError();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: buscador + chips de filtro
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar juego...',
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

          // ── Chips de género ───────────────────────────────────────────
          const _FilterLabel(label: 'Género'),
          const SizedBox(height: 6),
          const _GenreFilterRow(),
          const SizedBox(height: 10),

          // ── Chips de plataforma ────────────────────────────────────────
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

class _GenreFilterRow extends StatelessWidget {
  const _GenreFilterRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiExplorerProvider>();
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ExplorerFilters.genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final genre = ExplorerFilters.genres[index];
          final isSelected = provider.selectedGenre == genre;
          return _FilterChip(
            label: genre,
            isSelected: isSelected,
            onTap: () => provider.setGenre(genre),
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
    final provider = context.watch<ApiExplorerProvider>();
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ExplorerFilters.platforms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final platform = ExplorerFilters.platforms[index];
          final isSelected = provider.selectedPlatform == platform;
          return _FilterChip(
            label: platform,
            isSelected: isSelected,
            onTap: () => provider.setPlatform(platform),
          );
        },
      ),
    );
  }
}

/// Chip de filtro monocromático — seleccionado = fondo negro, texto blanco.
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
            color: isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados: error, vacío
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin conexión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _EmptyState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
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
            Text(
              query.isNotEmpty
                  ? 'No hay juegos para "$query"'
                  : 'Prueba con otro filtro',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
// Card de juego RAWG — paleta monocromática
// ─────────────────────────────────────────────────────────────────────────────

class _RawgGameCard extends StatelessWidget {
  final Map<String, dynamic> rawgItem;
  final VoidCallback onSave;

  const _RawgGameCard({required this.rawgItem, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final name = rawgItem['name'] as String? ?? 'Sin nombre';
    final image = rawgItem['background_image'] as String?;
    final rating = rawgItem['rating']?.toString() ?? 'N/A';
    final released = rawgItem['released'] as String? ?? '';
    final genres = (rawgItem['genres'] as List<dynamic>?)
            ?.take(2)
            .map((g) => g['name'] as String)
            .join(', ') ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ──────────────────────────────────────────────────
            if (image != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 150,
                    color: AppColors.surface,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textTertiary,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 150,
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textTertiary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      genres,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Fila inferior: rating · fecha · botón ────────────
                  Row(
                    children: [
                      // Rating monocromático
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (released.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          released,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Botón guardar — negro sólido
                      Material(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: onSave,
                          borderRadius: BorderRadius.circular(8),
                          splashColor: AppColors.accentLight,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: AppColors.background,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.background,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}