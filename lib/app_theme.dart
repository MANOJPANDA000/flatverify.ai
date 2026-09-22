import 'package:flutter/material.dart';
import 'branding.dart';

class AppLayout {
  static const maxContentWidth = 1280.0;
  static const pagePadding = EdgeInsets.all(20);
  static const sectionGap = 20.0;
}

ThemeData buildAppTheme() {
  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      indicatorColor: const Color(0xFFEAF1FF),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.secondaryText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.secondaryText,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF2563EB),
      surface: Colors.white,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFFEAF0F8),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.secondaryText,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAFBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF68758B)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    ),
  );
  return theme.copyWith(
    chipTheme: ChipThemeData(
      selectedColor: const Color(0xFFEAF1FF),
      backgroundColor: const Color(0xFFF7F9FC),
      checkmarkColor: AppColors.primary,
      labelStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334A6B),
      ),
      side: const BorderSide(color: Color(0xFFE4EAF3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE7ECF3),
      thickness: 1,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
      iconColor: AppColors.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: theme.segmentedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    ),
    textTheme: theme.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.dark)
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 26,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.text,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.text,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.secondaryText,
          ),
        )
        .apply(fontFamily: theme.textTheme.bodyMedium?.fontFamily),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
