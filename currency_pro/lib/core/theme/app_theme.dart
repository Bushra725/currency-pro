import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Builds a full [ThemeData] from an [AppPalette].
class AppTheme {
  const AppTheme._();

  static ThemeData build(AppPalette p) {
    final ColorScheme scheme = p.isDark
        ? ColorScheme.dark(
            primary: p.primary,
            onPrimary: p.onPrimary,
            secondary: p.accent,
            onSecondary: p.onPrimary,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.down,
            onError: Colors.white,
            outline: p.outline,
          )
        : ColorScheme.light(
            primary: p.primary,
            onPrimary: p.onPrimary,
            secondary: p.accent,
            onSecondary: p.onPrimary,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.down,
            onError: Colors.white,
            outline: p.outline,
          );

    final TextTheme text = Typography.material2021()
        .englishLike
        .apply(
          bodyColor: p.textPrimary,
          displayColor: p.textPrimary,
        )
        .copyWith(
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
            letterSpacing: 0.2,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: p.textPrimary),
          bodySmall: TextStyle(fontSize: 12, color: p.textSecondary),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.outline,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        // Matching the page background removes the colour band that used to
        // appear between the bar and the content beneath it.
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
          letterSpacing: 0.8,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              p.isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              p.isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              p.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        selectedColor: p.primary,
        selectedTileColor: p.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      // Rules are now whisper-soft; most screens separate content with
      // spacing and fill instead of drawing a line.
      dividerTheme:
          DividerThemeData(color: p.hairline, thickness: 1, space: 1),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        width: 304,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHigh,
        contentTextStyle: TextStyle(color: p.textPrimary, fontSize: 13),
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: TextStyle(color: p.textSecondary),
        labelStyle: TextStyle(color: p.textSecondary),
        // Fields read as soft filled pills; only focus draws a ring.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.down, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.down, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(0, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.surfaceAlt,
          side: BorderSide.none,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll<TextStyle>(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primary,
        // No outline — selection is communicated by fill, not by a stroke.
        side: BorderSide.none,
        labelStyle: TextStyle(color: p.textPrimary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? p.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? p.primary.withOpacity(0.35)
              : null,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        thumbColor: p.primary,
        inactiveTrackColor: p.surfaceAlt,
        overlayColor: p.primary.withOpacity(0.14),
        trackHeight: 4,
        valueIndicatorColor: p.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceAlt,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(fontSize: 11.5, color: p.textPrimary),
      ),
    );
  }
}
