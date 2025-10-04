import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

ThemeData buildPaisaTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2BB39A),
    onPrimary: Color(0xFF06231E),
    primaryContainer: Color(0xFF0E3B33),
    onPrimaryContainer: Color(0xFFBDEFE6),
    secondary: Color(0xFF334155),
    onSecondary: Color(0xFFE6EDF6),
    secondaryContainer: Color(0xFF1F2A3A),
    onSecondaryContainer: Color(0xFFD7E2F3),
    tertiary: Color(0xFFC89B3C),
    onTertiary: Color(0xFF251A05),
    tertiaryContainer: Color(0xFF3C2D12),
    onTertiaryContainer: Color(0xFFF2E3BF),
    error: Color(0xFFEF4444),
    onError: Color(0xFF1F0A0A),
    errorContainer: Color(0xFF4C1111),
    onErrorContainer: Color(0xFFFCDADA),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFE6EDF6),
    surfaceDim: Color(0xFF0B1220),
    surfaceBright: Color(0xFF1F2A3A),
    surfaceContainerLowest: Color(0xFF0B1220),
    surfaceContainerLow: Color(0xFF101827),
    surfaceContainer: Color(0xFF131D2C),
    surfaceContainerHigh: Color(0xFF162030),
    surfaceContainerHighest: Color(0xFF1F2A3A),
    onSurfaceVariant: Color(0xFFA8B3C7),
    outline: Color(0xFF1F2A3A),
    outlineVariant: Color(0xFF273345),
    shadow: Color(0x80000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFFE6EDF6),
    onInverseSurface: Color(0xFF0B1220),
    inversePrimary: Color(0xFF7CDAC8),
    surfaceTint: Color(0xFF2BB39A),
  );

  const colorTokens = PaisaColorTokens.dark;
  final textTheme = PaisaTypography.textTheme(
    colorTokens.textPrimary,
    colorTokens.textSecondary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorTokens.backgroundRoot,
    canvasColor: colorTokens.backgroundSurface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: colorTokens.textPrimary,
      titleTextStyle: textTheme.titleLarge,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colorTokens.backgroundSurface,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorTokens.borderDivider),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorTokens.borderDivider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorTokens.brandPrimary,
      foregroundColor: colorTokens.brandOnPrimary,
      shape: const StadiumBorder(),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorTokens.navigationBackground,
      selectedItemColor: colorTokens.accentGold,
      unselectedItemColor: colorTokens.navigationInactive,
      selectedLabelStyle:
          textTheme.labelMedium?.copyWith(color: colorTokens.accentGold),
      unselectedLabelStyle:
          textTheme.labelMedium?.copyWith(color: colorTokens.navigationInactive),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      PaisaColorTokens.dark,
    ],
  );
}
