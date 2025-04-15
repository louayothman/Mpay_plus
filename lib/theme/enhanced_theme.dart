import 'package:flutter/material.dart';

class EnhancedTheme {
  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color primaryColorLight = Color(0xFF8E24AA); // Deep Purple 600
  static const Color primaryColorDark = Color(0xFF4A148C); // Deep Purple 900
  static const Color accentColor = Color(0xFF9C27B0); // Purple 500
  static const Color accentColorLight = Color(0xFFBA68C8); // Purple 300
  static const Color accentColorDark = Color(0xFF7B1FA2); // Purple 700

  // ألوان الحالة
  static const Color successColor = Color(0xFF4CAF50); // Green 500
  static const Color warningColor = Color(0xFFFFC107); // Amber 500
  static const Color errorColor = Color(0xFFF44336); // Red 500
  static const Color infoColor = Color(0xFF2196F3); // Blue 500

  // ألوان محايدة
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0); // Grey 300
  static const Color disabledColor = Color(0xFFBDBDBD); // Grey 400

  // ألوان النص
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color textHintColor = Color(0xFF9E9E9E); // Grey 500
  static const Color textOnPrimaryColor = Colors.white;
  static const Color textOnAccentColor = Colors.white;

  // تدرجات لونية
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColorLight, primaryColorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColorLight, accentColorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ظلال
  static List<BoxShadow> get smallShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get largeShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ];

  // نصف قطر الحواف
  static const double smallBorderRadius = 4.0;
  static const double mediumBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 24.0;
  static const double circularBorderRadius = 100.0;

  // المسافات البادئة
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // المسافات البينية
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // أحجام الخط
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double titleFontSize = 18.0;
  static const double headlineFontSize = 24.0;
  static const double displayFontSize = 32.0;

  // أنماط النص
  static const TextStyle headlineStyle = TextStyle(
    fontSize: headlineFontSize,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: mediumFontSize,
    color: textPrimaryColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: smallFontSize,
    color: textSecondaryColor,
  );

  // أنماط الأزرار
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primaryColor),
    foregroundColor: MaterialStateProperty.all(textOnPrimaryColor),
    padding: MaterialStateProperty.all(
      EdgeInsets.symmetric(
        horizontal: largePadding,
        vertical: mediumPadding,
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumBorderRadius),
      ),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.transparent),
    foregroundColor: MaterialStateProperty.all(primaryColor),
    padding: MaterialStateProperty.all(
      EdgeInsets.symmetric(
        horizontal: largePadding,
        vertical: mediumPadding,
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumBorderRadius),
        side: BorderSide(color: primaryColor),
      ),
    ),
  );

  // أنماط البطاقات
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(mediumBorderRadius),
    boxShadow: smallShadow,
  );

  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(mediumBorderRadius),
    boxShadow: mediumShadow,
  );

  // أنماط حقول الإدخال
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(mediumBorderRadius),
      borderSide: BorderSide(color: dividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(mediumBorderRadius),
      borderSide: BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(mediumBorderRadius),
      borderSide: BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(mediumBorderRadius),
      borderSide: BorderSide(color: errorColor),
    ),
    contentPadding: EdgeInsets.all(mediumPadding),
  );

  // إنشاء سمة كاملة
  static ThemeData createTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      colorScheme: ColorScheme(
        primary: primaryColor,
        primaryContainer: primaryColorDark,
        secondary: accentColor,
        secondaryContainer: accentColorDark,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: textOnPrimaryColor,
        onSecondary: textOnAccentColor,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      disabledColor: disabledColor,
      fontFamily: 'Cairo',
      textTheme: TextTheme(
        displayLarge: headlineStyle.copyWith(fontSize: displayFontSize),
        displayMedium: headlineStyle,
        titleLarge: titleStyle,
        bodyLarge: bodyStyle.copyWith(fontSize: largeFontSize),
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      inputDecorationTheme: inputDecoration,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: textOnAccentColor,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallBorderRadius),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: primaryColor.withOpacity(0.2),
        linearTrackColor: primaryColor.withOpacity(0.2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        valueIndicatorColor: primaryColor,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryColorDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        textStyle: captionStyle.copyWith(color: Colors.white),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeBorderRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(largeBorderRadius),
            topRight: Radius.circular(largeBorderRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: bodyStyle.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }
}
