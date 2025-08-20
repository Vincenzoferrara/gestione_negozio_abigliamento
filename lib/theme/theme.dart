import 'package:flutter/material.dart';

// Classe che definisce i temi dell'applicazione (chiaro e scuro).
class AppTheme {
  // Definizione dei colori principali e costanti.
  static const Color primaryColor = Colors.redAccent;
  static const Color primaryColorDark = Color(0xFFD32F2F); // Un rosso più scuro
  static const Color accentColor = Color(0xFFFF5722); // Colore di accento
  static const Color backgroundColor = Color(0xFFFAFAFA); // Sfondo per tema chiaro
  static const Color surfaceColor = Colors.white; // Colore per superfici come le Card
  static const Color errorColor = Color(0xFFB00020); // Colore per gli errori

  // Colori per i gradienti personalizzati.
  static const Color lightGradientStart = Color(0xFFFFEBEE); // Inizio gradiente chiaro
  static const Color lightGradientEnd = Color(0xFFFFFFFF); // Fine gradiente chiaro
  static const Color darkGradientStart = Color(0xFF121212); // Inizio gradiente scuro
  static const Color darkGradientEnd = Color(0xFF1A0000); // Fine gradiente scuro

  // Getter statico per ottenere l'oggetto ThemeData per il tema chiaro.
  static ThemeData get lightTheme {
    return ThemeData(
      // Abilita l'uso di Material 3.
      useMaterial3: true,
      // Specifica che questo è un tema con luminosità chiara.
      brightness: Brightness.light,
      
      // Definisce lo schema di colori a partire da un colore seme (seed).
      // Flutter deriva gli altri colori (secondary, tertiary, etc.) da questo.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // Registra le estensioni personalizzate del tema.
      extensions: <ThemeExtension<dynamic>>[
        AppColorExtension.light,
      ],
      
      // Impostazioni legacy (ancora utili per compatibilità).
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      // Personalizzazione del tema per AppBar.
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // Colore per icone e testo
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Personalizzazione del tema per Drawer (menu laterale).
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
      
      // Personalizzazione del tema per Card.
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // Personalizzazione del tema per ListTile.
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        dense: true, // Rende i ListTile più compatti
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Personalizzazione del tema per i campi di input (es. TextField).
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
      
      // Personalizzazione del tema per ElevatedButton.
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
      
      // Personalizzazione del tema per TextButton.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Personalizzazione del tema globale per le icone.
      iconTheme: IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      
      // Definizione degli stili di testo globali.
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54),
      ),
      
      // Adatta la densità dei componenti alla piattaforma.
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // Getter statico per ottenere l'oggetto ThemeData per il tema scuro.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Schema di colori per il tema scuro.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      
      // Registra l'estensione personalizzata per il tema scuro.
      extensions: <ThemeExtension<dynamic>>[
        AppColorExtension.dark,
      ],
      
      primarySwatch: Colors.red,
      primaryColor: primaryColor,
      
      // Tema per AppBar in modalità scura.
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
      
      // Tema per Drawer in modalità scura.
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.grey.shade900,
        elevation: 8,
      ),
      
      // Tema per Card in modalità scura.
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // Tema per ListTile in modalità scura.
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        textColor: Colors.white,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Tema per campi di input in modalità scura.
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
      
      // Tema per ElevatedButton in modalità scura.
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
      
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

// Definisce una classe per estendere il ThemeData con colori personalizzati.
// Questo permette di accedere a colori specifici tramite Theme.of(context).extension<AppColorExtension>()!
@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  // Costruttore della classe di estensione.
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

  // Dichiarazione dei colori personalizzati.
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

  // Istanza statica con i colori per il tema chiaro.
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
    stockAvailable: Color(0xFF4CAF50), // Verde
    stockUnavailable: Color(0xFFF44336), // Rosso
  );

  // Istanza statica con i colori per il tema scuro.
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
    stockAvailable: Color(0xFF4CAF50), // Verde
    stockUnavailable: Color(0xFFF44336), // Rosso
  );

  // Metodo obbligatorio per creare una copia dell'estensione, eventualmente con nuovi valori.
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

  // Metodo obbligatorio per l'interpolazione lineare tra due temi (usato per le animazioni di cambio tema).
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