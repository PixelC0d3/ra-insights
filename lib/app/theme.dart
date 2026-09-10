/// Dark Material 3 theme. Palette carried over from the userscript so the
/// insights read the same on both surfaces.
library;

import 'package:flutter/material.dart';

import '../domain/insights/rarity.dart';

class RaColors {
  static const background = Color(0xFF0B0B0F);
  static const surface = Color(0xFF16161C);
  static const surfaceAlt = Color(0xFF1E1E26);
  static const border = Color(0xFF2A2A34);
  static const achievements = Color(0xFF3B82F6);
  static const mastered = Color(0xFFFBBF24);
  static const beaten = Color(0xFFA3A3A3);
  static const points = Color(0xFFA78BFA);
  static const streak = Color(0xFFF97316);
  static const muted = Color(0xFF8A8A96);

  // Rarity ramp: grey → green → blue → purple → amber, escalating the way
  // loot tiers do in the games this app is about.
  static const rarityCommon = Color(0xFF9CA3AF);
  static const rarityUncommon = Color(0xFF4ADE80);
  static const rarityRare = achievements;
  static const rarityVeryRare = points;
  static const rarityUltraRare = mastered;
}

Color rarityColor(RarityTier tier) => switch (tier) {
      RarityTier.common => RaColors.rarityCommon,
      RarityTier.uncommon => RaColors.rarityUncommon,
      RarityTier.rare => RaColors.rarityRare,
      RarityTier.veryRare => RaColors.rarityVeryRare,
      RarityTier.ultraRare => RaColors.rarityUltraRare,
    };

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: RaColors.achievements,
    brightness: Brightness.dark,
    surface: RaColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RaColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: RaColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: RaColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: RaColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RaColors.surface,
      indicatorColor: RaColors.achievements.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RaColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RaColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: RaColors.border, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
