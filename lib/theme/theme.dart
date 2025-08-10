import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.redAccent;
  static const Color primaryColorDark = Color(0xFFD32F2F);
  static const Color accentColor = Color(0xFFFF5722);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  // Colori personalizzati per gradient
  static const Color lightGradientStart = Color(0xFFFFEBEE);
  static const Color lightGradientEnd = Color(0xFFFFFFFF);
  static const Color darkGradientStart = Color(0xFF121212);
  static const Color darkGradientEnd = Color(0xFF1A0000);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // Extensions personalizzate
      extensions: <ThemeExtension<dynamic>>[
        AppColorExtension.light,
      ],
      
      // Primary Colors
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
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
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
        ),
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      
      // Extensions personalizzate
      extensions: <ThemeExtension<dynamic>>[
        AppColorExtension.dark,
      ],
      
      // Primary Colors
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
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
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.grey.shade900,
        elevation: 8,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        textColor: Colors.white,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

// Extension per colori personalizzati
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

  static const AppColorExtension light = AppColorExtension(
    gradientStart: AppTheme.lightGradientStart,
    gradientEnd: AppTheme.lightGradientEnd,
    cardIconColor: AppTheme.primaryColor,
    subtitleColor: Color(0xFF757575),
    fabGradientStart: AppTheme.primaryColor,
    fabGradientEnd: Color(0xFFE53935),
    headerGradientStart: AppTheme.primaryColor,
    headerGradientEnd: Color(0xFFE53935),
    selectedCardBackground: Color(0xFFFFF3E0),
    variantSelectedBackground: Color(0xFFFFEBEE),
    priceBackground: Color(0xFFE8F5E8),
    stockAvailable: Color(0xFF4CAF50),
    stockUnavailable: Color(0xFFF44336),
  );

  static const AppColorExtension dark = AppColorExtension(
    gradientStart: AppTheme.darkGradientStart,
    gradientEnd: AppTheme.darkGradientEnd,
    cardIconColor: AppTheme.primaryColor,
    subtitleColor: Color(0xFFBDBDBD),
    fabGradientStart: AppTheme.primaryColor,
    fabGradientEnd: Color(0xFFE53935),
    headerGradientStart: AppTheme.primaryColor,
    headerGradientEnd: Color(0xFFE53935),
    selectedCardBackground: Color(0xFF1A0000),
    variantSelectedBackground: Color(0xFF2C1B1B),
    priceBackground: Color(0xFF1B2A1B),
    stockAvailable: Color(0xFF4CAF50),
    stockUnavailable: Color(0xFFF44336),
  );

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
    );
  }
}