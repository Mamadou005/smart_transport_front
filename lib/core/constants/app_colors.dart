import 'package:flutter/material.dart';

class AppColors {
  // Primaires
  static const Color primary        = Color(0xFF0A2342);  // Navy profond
  static const Color primaryLight   = Color(0xFF1B4F8A);
  static const Color accent         = Color(0xFF00D4AA);  // Turquoise vif
  static const Color accentOrange   = Color(0xFFFF6B35);  // Orange énergie

  // ✅ Bagagiste (vert, distinct du teal Agent Terminal)
  static const Color bagagisteDark   = Color(0xFF1B5E20);
  static const Color bagagisteLight  = Color(0xFF43A047);
  static const Color bagagisteAccent = Color(0xFF2E7D32);

  // Neutres
  static const Color background     = Color(0xFFF4F6FB);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceDark    = Color(0xFF0D1B2A);

  // Textes
  static const Color textDark       = Color(0xFF0A2342);
  static const Color textMedium     = Color(0xFF4A5568);
  static const Color textLight      = Color(0xFF9AA5B4);

  // Status
  static const Color success        = Color(0xFF00C48C);
  static const Color warning        = Color(0xFFFFB020);
  static const Color error          = Color(0xFFFF4D4F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A2342), Color(0xFF1B4F8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A8C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B4F8A), Color(0xFF0A2342)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Gradient Agent Terminal (bleu → turquoise, comme dans la maquette)
  static const LinearGradient agentGradient = LinearGradient(
    colors: [Color(0xFF1B4F8A), Color(0xFF00D4AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Gradient Bagagiste (vert, comme dans la maquette)
  static const LinearGradient bagagisteGradient = LinearGradient(
    colors: [bagagisteDark, bagagisteLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}