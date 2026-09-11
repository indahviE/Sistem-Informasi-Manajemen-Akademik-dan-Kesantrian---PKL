import 'package:flutter/material.dart';

/// Palet Core Dashboard (template admin) — aksen biru #2A85FF.
class Tw {
  Tw._();

  static const primary = Color(0xFF2A85FF); // biru Core
  static const primaryDark = Color(0xFF1A6FE0);
  static const primaryLight = Color(0xFFB1E5FC); // baby blue
  static const primarySoft = Color(0xFFE8F1FF);

  static const purple = Color(0xFF8E59FF);
  static const purpleSoft = Color(0xFFCABDFF);

  static const gray50 = Color(0xFFF4F4F4); // bgLight
  static const gray100 = Color(0xFFEFEFEF); // highlight
  static const gray200 = Color(0xFFE5E7EB);
  static const gray400 = Color(0xFF9A9FA5); // textGrey
  static const gray500 = Color(0xFF6F767E); // textLight
  static const gray600 = Color(0xFF5A6068);
  static const gray700 = Color(0xFF52565C);
  static const gray800 = Color(0xFF4A4E54);
  static const gray900 = Color(0xFF272B30); // title

  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFFF6A55);
  static const redSoft = Color(0xFFFFE7E4); // mistyrose
  static const amber = Color(0xFFF5A623);
  static const amberSoft = Color(0xFFFFD88D); // pale yellow
  static const teal = Color(0xFF83BF6E); // success green
  static const tealSoft = Color(0xFFB5E4CA); // mint
  static const sky = Color(0xFF2A85FF);
  static const skySoft = Color(0xFFB1E5FC);
  static const indigo = Color(0xFF8E59FF);
  static const indigoSoft = Color(0xFFCABDFF); // lavender
  static const violet = Color(0xFF8E59FF);
  static const violetSoft = Color(0xFFCABDFF);
  static const peach = Color(0xFFFFBC99);
  static const peachSoft = Color(0xFFFFE7E4);

  static const sidebar = Color(0xFF101014);
  static const sidebarDark = Color(0xFF0C0C0E);
}

class AppTheme {
  AppTheme._();

  static ThemeData light([Color seed = Tw.primary]) {
    final primary = seed;
    final primaryDark = Color.lerp(seed, Colors.black, 0.22)!;
    final primaryLight = Color.lerp(seed, Colors.white, 0.72)!;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: Tw.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        surface: Tw.white,
        onSurface: Tw.gray900,
        secondary: Tw.teal,
        outline: Tw.gray200,
      ),
      scaffoldBackgroundColor: Tw.gray50,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Tw.white,
        foregroundColor: Tw.gray900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Tw.gray900,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFCFCFC),
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Tw.gray100, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tw.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Tw.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Tw.gray100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Tw.gray500),
        hintStyle: const TextStyle(color: Tw.gray400),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Tw.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: primary.withOpacity(0.25),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1),
          disabledBackgroundColor: Tw.gray200,
          disabledForegroundColor: Tw.gray500,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Tw.primary, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          disabledForegroundColor: Tw.gray400,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          disabledForegroundColor: Tw.gray400,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Tw.gray100, thickness: 1),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Tw.gray200),
        backgroundColor: Tw.gray100,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Tw.gray50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Tw.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Tw.gray100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
        menuStyle: MenuStyle(
          elevation: WidgetStateProperty.all(6),
          backgroundColor: WidgetStateProperty.all(Tw.white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Tw.gray900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Tw.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        extendedIconLabelSpacing: 8,
        extendedTextStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Tw.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
        barrierColor: Colors.black45,
        constraints: const BoxConstraints(minWidth: 420, maxWidth: 560),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Tw.gray100, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: Tw.gray900,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        contentTextStyle: const TextStyle(color: Tw.gray700, fontSize: 14, height: 1.45),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tw.white,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textColor: Tw.gray900,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Tw.primary),
    );
  }
}
