import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.redAccent;
  static const Color primaryColorDark = Color(0xFFD32F2F);
  static const Color accentColor = Color(0xFFFF5722);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  static const Color lightGradientStart = Color(0xFFFFEBEE);
  static const Color lightGradientEnd = Color(0xFFFFFFFF);
  static const Color darkGradientStart = Color(0xFF121212);
  static const Color darkGradientEnd = Color(0xFF1A0000);

  // Status colors (semantic)
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColorSemantic = Color(0xFFF44336);

  // ✅ TEMA LIGHT CORRETTO
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // ✅ IMPORTANTE: Registra SEMPRE l'estensione
      extensions: <ThemeExtension<dynamic>>[
        const AppColorExtension(
          gradientStart: lightGradientStart,
          gradientEnd: lightGradientEnd,
          cardIconColor: primaryColor,
          subtitleColor: Color(0xFF757575),
          fabGradientStart: primaryColor,
          fabGradientEnd: Color(0xFFE53935),
          headerGradientStart: primaryColor,
          headerGradientEnd: Color(0xFFE53935),
          selectedCardBackground: Color(0xFFFFF3E0),
          variantSelectedBackground: Color(0xFFFFEBEE),
          priceBackground: Color(0xFFE8F5E8),
          stockAvailable: Color(0xFF4CAF50),
          stockUnavailable: Color(0xFFF44336),
          successColor: successColor,
          warningColor: warningColor,
          errorColorStatus: errorColorSemantic,
        ),
      ],
      
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
      
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      listTileTheme: const ListTileThemeData(
        iconColor: primaryColor,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(inherit: true, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(inherit: true, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineSmall: TextStyle(inherit: true, fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: TextStyle(inherit: true, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: TextStyle(inherit: true, fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        titleSmall: TextStyle(inherit: true, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: TextStyle(inherit: true, fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
        bodyMedium: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87),
        bodySmall: TextStyle(inherit: true, fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54),
      ),
      
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // ✅ TEMA DARK CORRETTO
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      
      // ✅ IMPORTANTE: Registra SEMPRE l'estensione
      extensions: <ThemeExtension<dynamic>>[
        const AppColorExtension(
          gradientStart: darkGradientStart,
          gradientEnd: darkGradientEnd,
          cardIconColor: primaryColor,
          subtitleColor: Color(0xFFBDBDBD),
          fabGradientStart: primaryColor,
          fabGradientEnd: Color(0xFFE53935),
          headerGradientStart: primaryColor,
          headerGradientEnd: Color(0xFFE53935),
          selectedCardBackground: Color(0xFF1A0000),
          variantSelectedBackground: Color(0xFF2C1B1B),
          priceBackground: Color(0xFF1B2A1B),
          stockAvailable: Color(0xFF4CAF50),
          stockUnavailable: Color(0xFFF44336),
          successColor: successColor,
          warningColor: warningColor,
          errorColorStatus: errorColorSemantic,
        ),
      ],
      
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.grey.shade900,
        elevation: 8,
      ),
      
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      listTileTheme: const ListTileThemeData(
        iconColor: primaryColor,
        textColor: Colors.white,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(inherit: true, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(inherit: true, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(inherit: true, fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(inherit: true, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(inherit: true, fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(inherit: true, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(inherit: true, fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
        bodyMedium: TextStyle(inherit: true, fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),
        bodySmall: TextStyle(inherit: true, fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

// ✅ ESTENSIONE CORRETTA - Rimossa la gestione degli stati light/dark
@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardIconColor,
    required this.subtitleColor,
    required this.fabGradientStart,
    required this.fabGradientEnd,
    required this.headerGradientStart,
    required this.headerGradientEnd,
    required this.selectedCardBackground,
    required this.variantSelectedBackground,
    required this.priceBackground,
    required this.stockAvailable,
    required this.stockUnavailable,
    required this.successColor,
    required this.warningColor,
    required this.errorColorStatus,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color cardIconColor;
  final Color subtitleColor;
  final Color fabGradientStart;
  final Color fabGradientEnd;
  final Color headerGradientStart;
  final Color headerGradientEnd;
  final Color selectedCardBackground;
  final Color variantSelectedBackground;
  final Color priceBackground;
  final Color stockAvailable;
  final Color stockUnavailable;
  final Color successColor;
  final Color warningColor;
  final Color errorColorStatus;

  @override
  AppColorExtension copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? cardIconColor,
    Color? subtitleColor,
    Color? fabGradientStart,
    Color? fabGradientEnd,
    Color? headerGradientStart,
    Color? headerGradientEnd,
    Color? selectedCardBackground,
    Color? variantSelectedBackground,
    Color? priceBackground,
    Color? stockAvailable,
    Color? stockUnavailable,
    Color? successColor,
    Color? warningColor,
    Color? errorColorStatus,
  }) {
    return AppColorExtension(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      cardIconColor: cardIconColor ?? this.cardIconColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      fabGradientStart: fabGradientStart ?? this.fabGradientStart,
      fabGradientEnd: fabGradientEnd ?? this.fabGradientEnd,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      selectedCardBackground: selectedCardBackground ?? this.selectedCardBackground,
      variantSelectedBackground: variantSelectedBackground ?? this.variantSelectedBackground,
      priceBackground: priceBackground ?? this.priceBackground,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      stockUnavailable: stockUnavailable ?? this.stockUnavailable,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColorStatus: errorColorStatus ?? this.errorColorStatus,
    );
  }

  @override
  AppColorExtension lerp(ThemeExtension<AppColorExtension>? other, double t) {
    if (other is! AppColorExtension) {
      return this;
    }
    return AppColorExtension(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      cardIconColor: Color.lerp(cardIconColor, other.cardIconColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      fabGradientStart: Color.lerp(fabGradientStart, other.fabGradientStart, t)!,
      fabGradientEnd: Color.lerp(fabGradientEnd, other.fabGradientEnd, t)!,
      headerGradientStart: Color.lerp(headerGradientStart, other.headerGradientStart, t)!,
      headerGradientEnd: Color.lerp(headerGradientEnd, other.headerGradientEnd, t)!,
      selectedCardBackground: Color.lerp(selectedCardBackground, other.selectedCardBackground, t)!,
      variantSelectedBackground: Color.lerp(variantSelectedBackground, other.variantSelectedBackground, t)!,
      priceBackground: Color.lerp(priceBackground, other.priceBackground, t)!,
      stockAvailable: Color.lerp(stockAvailable, other.stockAvailable, t)!,
      stockUnavailable: Color.lerp(stockUnavailable, other.stockUnavailable, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColorStatus: Color.lerp(errorColorStatus, other.errorColorStatus, t)!,
    );
  }
}