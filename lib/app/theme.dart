import 'package:flutter/material.dart';

class AppTheme {
  // Restrained wine, burgundy, and rose palette inspired by the reference UI.
  static const Color crimsonBerry = Color(0xFFBA0C48);
  static const Color crimsonBerryLight = Color(0xFFC98A9A);
  static const Color crimsonBerryDark = Color(0xFF8A0934);
  static const Color electricPink = Color(0xFFA9576D);
  static const Color neonMagenta = Color(0xFF7A2942);
  static const Color deepPlum = Color(0xFF24131B);
  static const Color aqua = Color(0xFF8AC8C2);
  static const Color obsidianBlack = Color(0xFF0D0E13);
  static const Color slateCard = Color(0xFF161822);
  static const Color slateCardElevated = Color(0xFF1E212E);
  static const Color slateBorder = Color(0xFF232636);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFB5BECC);
  static const Color textMuted = Color(0xFF778397);
  static const Color chipInactive = Color(0xFF1C2533);
  static const Color chipActive = Color(0xFFD4145A);

  // Compatibility aliases
  static const Color cyberVolt = crimsonBerry;
  static const Color cyberVoltDark = crimsonBerryDark;
  static const Color matteObsidian = obsidianBlack;
  static const Color surfaceObsidian = slateCard;
  static const Color cardObsidian = slateCard;
  static const Color obsidianCard = slateCard;
  static const Color obsidianCardLight = slateCardElevated;
  static const Color borderObsidian = slateBorder;

  static const Color neoVolt = crimsonBerry;
  static const Color neoCream = obsidianBlack;
  static const Color neoInk = textPrimary;
  static const Color neoLavender = slateCard;
  static const Color neoPeach = slateCard;
  static const Color neoSky = slateCard;
  static const Color neoAmber = slateCard;
  static const Color neoMint = slateCard;

  static const LinearGradient crimsonGradient = LinearGradient(
    colors: [Color(0xFF542337), Color(0xFF7A2942), Color(0xFF542337)],
    begin: Alignment.centerLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF24131B), Color(0xFF7A2942), Color(0xFF542337)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    final baseTextTheme = Typography.whiteMountainView;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textSecondary,
          height: 1.45,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          height: 1.4,
        ),
      ),
      scaffoldBackgroundColor: obsidianBlack,
      canvasColor: obsidianBlack,
      cardColor: slateCard,
      dividerColor: slateBorder,
      colorScheme: const ColorScheme.dark(
        primary: crimsonBerry,
        onPrimary: Colors.white,
        secondary: crimsonBerryLight,
        onSecondary: Colors.white,
        tertiary: aqua,
        onTertiary: obsidianBlack,
        surface: slateCard,
        onSurface: textPrimary,
        error: Color(0xFFFF5252),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: const CardThemeData(
        color: slateCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: slateBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF100D18),
        elevation: 0,
        height: 76,
        indicatorColor: crimsonBerry.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? textPrimary : textMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? crimsonBerryLight : textMuted,
            size: selected ? 24 : 22,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricPink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: slateBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: crimsonBerryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF13101B),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: crimsonBerry, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.8),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: slateCardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: slateBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slateCard,
        selectedColor: crimsonBerry,
        secondarySelectedColor: crimsonBerry,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: slateBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        checkmarkColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: slateCardElevated,
        contentTextStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: crimsonBerry,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }

  /// Unified theme for lightTheme call as well, eliminating dual theme discrepancies
  static ThemeData get lightTheme => darkTheme;
}
