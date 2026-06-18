import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:games_vault/core/theme/app_colors.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';

/// Pantalla principal — Menú con tarjetas de navegación.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Header ──────────────────────────────────────────────────
              const Text(
                'Games\nCollection',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.05,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Administra tu colección de videojuegos',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),

              const SizedBox(height: 36),

              // ── Stats Card ───────────────────────────────────────────────
              // Firma del diseño: acento izquierdo mediante Stack + ClipRRect
              // para evitar la restricción de Flutter sobre bordes no-uniformes
              // con borderRadius.
              Consumer<CollectionProvider>(
                builder: (context, provider, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Capa base: borde uniforme + fondo
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Número grande como elemento visual
                              Text(
                                '${provider.totalGames}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Separador vertical sutil
                              Container(
                                width: 1,
                                height: 40,
                                color: AppColors.divider,
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'juegos',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(
                                    'en tu colección',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Acento izquierdo: barra negra superpuesta
                        const Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: 3,
                            child: ColoredBox(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // ── Menu label ───────────────────────────────────────────────
              const Text(
                'MENÚ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 14),

              // ── Navigation List ──────────────────────────────────────────
              _MenuCard(
                icon: Icons.collections_bookmark_rounded,
                label: 'Mi Colección',
                subtitle: 'CRUD local',
                onTap: () => Navigator.pushNamed(context, '/collection'),
              ),
              const SizedBox(height: 10),
              _MenuCard(
                icon: Icons.explore_rounded,
                label: 'Explorar',
                subtitle: 'RAWG API',
                onTap: () => Navigator.pushNamed(context, '/explorer'),
              ),
              const SizedBox(height: 10),
              _MenuCard(
                icon: Icons.info_outline_rounded,
                label: 'Acerca de',
                subtitle: 'Créditos',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de menú — fila horizontal: icono · texto · chevron.
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.divider,
        highlightColor: AppColors.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.text, size: 20),
              ),
              const SizedBox(width: 14),
              // Textos — ocupan el espacio restante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}