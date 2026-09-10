import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryLighter = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5C2D91);
  static const Color primaryDeep = Color(0xFF1E0A3C);

  // Accent Colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);

  // Background
  static const Color background = Color(0xFFF8F7FF);
  static const Color backgroundSecondary = Color(0xFFF1F0FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F3FF);

  // Dark Nav
  static const Color navBackground = Color(0xFF1E0A3C);
  static const Color navActive = Color(0xFFEDE9FE);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);

  // Card Colors (workspace palettes)
  static const Color cardPurple = Color(0xFFEDE9FE);
  static const Color cardBlue = Color(0xFFDBEAFE);
  static const Color cardGreen = Color(0xFFD1FAE5);
  static const Color cardOrange = Color(0xFFFEF3C7);
  static const Color cardPink = Color(0xFFFCE7F3);
  static const Color cardTeal = Color(0xFFCCFBF1);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF22C55E);

  // Status Colors
  static const Color statusActive = Color(0xFF22C55E);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusDone = Color(0xFF8B5CF6);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusPaused = Color(0xFF6B7280);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navGradient = LinearGradient(
    colors: [Color(0xFF1E0A3C), Color(0xFF2D1B69)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF59E0B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Workspace Theme Colors
  static List<Color> workspaceColors = [
    const Color(0xFF7C3AED),
    const Color(0xFF3B82F6),
    const Color(0xFF22C55E),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
    const Color(0xFF8B5CF6),
  ];
}
