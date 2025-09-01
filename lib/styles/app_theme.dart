import 'package:family_finances/styles/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme{
  static ColorScheme get appColorScheme => ColorScheme.fromSeed(seedColor: AppColors.primary);
  static ThemeData get appTheme => ThemeData(
    colorScheme: appColorScheme,
        useMaterial3: true,
    primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'sans-serif',
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF2A8782),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
        );
}