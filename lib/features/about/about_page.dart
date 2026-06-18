import 'package:flutter/material.dart';
import 'package:games_vault/core/theme/app_colors.dart';

/// Pantalla de créditos — diseño editorial minimalista.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ────────────────────────────────────────────────
            const _AppHeader(),

            const Divider(height: 1),

            // ── Secciones ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'Descripción'),
                  const SizedBox(height: 12),
                  const Text(
                    'Aplicación de gestión de colección de videojuegos. '
                    'Permite administrar tu biblioteca personal y explorar '
                    'nuevos títulos a través de la API de RAWG.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 32),
                  const _SectionLabel(label: 'Stack técnico'),
                  const SizedBox(height: 12),
                  const _TechStack(),

                  const SizedBox(height: 32),
                  const _SectionLabel(label: 'Créditos'),
                  const SizedBox(height: 12),
                  const _CreditsRow(
                    label: 'Desarrollador',
                    value: 'Proyecto académico',
                  ),
                  const _CreditsRow(
                    label: 'Contexto',
                    value: 'Taller de Flutter',
                  ),
                  const _CreditsRow(
                    label: 'Versión',
                    value: '1.0.0',
                  ),

                  const SizedBox(height: 40),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header con identidad de la app
// ─────────────────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono de app
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.games_rounded,
              size: 30,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 18),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Games Collection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gestión de videojuegos',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stack técnico — lista de tecnologías con separadores
// ─────────────────────────────────────────────────────────────────────────────

class _TechStack extends StatelessWidget {
  const _TechStack();

  static const _items = [
    (icon: Icons.flutter_dash_rounded,  label: 'Flutter & Dart',         note: 'Framework UI'),
    (icon: Icons.storage_rounded,        label: 'MongoDB',                note: 'Base de datos local'),
    (icon: Icons.api_rounded,            label: 'RAWG API',               note: 'Catálogo de juegos'),
    (icon: Icons.account_tree_rounded,   label: 'Provider',               note: 'State management'),
    (icon: Icons.image_rounded,          label: 'Cached Network Image',   note: 'Carga de imágenes'),
    (icon: Icons.photo_library_rounded,  label: 'Image Picker',           note: 'Selección de galería'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            _TechRow(
              icon: _items[i].icon,
              label: _items[i].label,
              note: _items[i].note,
            ),
            if (i < _items.length - 1)
              const Divider(height: 1, indent: 52),
          ],
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String note;

  const _TechRow({
    required this.icon,
    required this.label,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Créditos — filas clave/valor con separador
// ─────────────────────────────────────────────────────────────────────────────

class _CreditsRow extends StatelessWidget {
  final String label;
  final String value;

  const _CreditsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hecho con Flutter',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}