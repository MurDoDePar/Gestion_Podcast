import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs
  static const Color bgColor = Color(0xFF0F1016);
  static const Color surfaceColor = Color(0xFF1E202C);
  static const Color primaryColor = Color(0xFF8A2BE2);
  static const Color accentColor = Color(0xFFFF1493);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A4B8);
  static const Color dangerColor = Color(0xFFFF4757);

  // Gradient Primaire
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      fontFamily: 'Outfit', // Assurez-vous d'ajouter cette police plus tard
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: dangerColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'Outfit',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // On utilisera un container pour le gradient
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
