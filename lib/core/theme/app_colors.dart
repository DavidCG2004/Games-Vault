import 'package:flutter/material.dart';

/// Paleta de colores — Minimalista monocromático.
/// Escala de grises con blanco como fondo base.
class AppColors {
  AppColors._();

  // ── Fondos ────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF); // Blanco puro
  static const Color surface    = Color(0xFFF5F5F5); // Gris muy claro
  static const Color card       = Color(0xFFFAFAFA); // Casi blanco

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color text          = Color(0xFF0A0A0A); // Negro casi puro
  static const Color textSecondary = Color(0xFF6B6B6B); // Gris medio
  static const Color textTertiary  = Color(0xFFAAAAAA); // Gris claro

  // ── Acento / Interactivos ─────────────────────────────────────────────────
  static const Color accent      = Color(0xFF0A0A0A); // Negro — CTA primario
  static const Color accentLight = Color(0xFF424242); // Gris oscuro — secundario

  // ── Bordes y divisores ────────────────────────────────────────────────────
  static const Color divider    = Color(0xFFE8E8E8); // Borde sutil
  static const Color border     = Color(0xFFD4D4D4); // Borde estándar

  // ── Estados semánticos (neutros) ──────────────────────────────────────────
  static const Color success = Color(0xFF2D2D2D); // Mismo negro — sin color semántico
  static const Color danger  = Color(0xFF1A1A1A);
  static const Color warning = Color(0xFF3D3D3D);
}