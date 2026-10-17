import 'package:flutter/material.dart';

class AppColors {
  static const fondo = Color(0xFF0B0F14);
  static const superficie = Color(0xFF111820);
  static const borde = Color(0xFF1E3447);
  static const acento = Color(0xFF079AEF);
  static const acentoSuave = Color(0x26079AEF);
  static const textoSecundario = Color(0xFF91A0B1);
}

/// Tipografía global de la aplicación.
/// Cambia [fuentePrincipal] para actualizarla en todas las pantallas.
class AppTypography {
  static const fuentePrincipal = 'Roboto';
}

class AppTheme {
  static OutlineInputBorder _borde(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  static ThemeData get tema {
    final esquema =
        ColorScheme.fromSeed(
          seedColor: AppColors.acento,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.acento,
          onPrimary: Colors.white,
          surface: AppColors.superficie,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fuentePrincipal,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textoSecundario),
        border: _borde(AppColors.borde),
        enabledBorder: _borde(AppColors.borde),
        focusedBorder: _borde(AppColors.acento),
        errorBorder: _borde(Colors.redAccent),
        focusedErrorBorder: _borde(Colors.redAccent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acento,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.acento),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.superficie,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
    );
  }
}
