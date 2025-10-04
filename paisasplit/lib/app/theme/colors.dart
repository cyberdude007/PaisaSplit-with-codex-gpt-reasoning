import 'package:flutter/material.dart';

@immutable
class PaisaColorTokens extends ThemeExtension<PaisaColorTokens> {
  const PaisaColorTokens({
    required this.backgroundRoot,
    required this.backgroundSurface,
    required this.borderDivider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.brandPrimary,
    required this.brandOnPrimary,
    required this.accentGold,
    required this.accentOnGold,
    required this.stateSuccess,
    required this.stateError,
    required this.stateWarn,
    required this.stateInfo,
    required this.navigationInactive,
    required this.navigationBackground,
  });

  final Color backgroundRoot;
  final Color backgroundSurface;
  final Color borderDivider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color brandPrimary;
  final Color brandOnPrimary;
  final Color accentGold;
  final Color accentOnGold;
  final Color stateSuccess;
  final Color stateError;
  final Color stateWarn;
  final Color stateInfo;
  final Color navigationInactive;
  final Color navigationBackground;

  static const PaisaColorTokens dark = PaisaColorTokens(
    backgroundRoot: Color(0xFF0B1220),
    backgroundSurface: Color(0xFF0F172A),
    borderDivider: Color(0xFF1F2A3A),
    textPrimary: Color(0xFFE6EDF6),
    textSecondary: Color(0xFFA8B3C7),
    textDisabled: Color(0xFF6B7280),
    brandPrimary: Color(0xFF2BB39A),
    brandOnPrimary: Color(0xFF06231E),
    accentGold: Color(0xFFC89B3C),
    accentOnGold: Color(0xFF251A05),
    stateSuccess: Color(0xFF22C55E),
    stateError: Color(0xFFEF4444),
    stateWarn: Color(0xFFF59E0B),
    stateInfo: Color(0xFF38BDF8),
    navigationInactive: Color(0xFF94A3B8),
    navigationBackground: Color(0xFF0F172A),
  );

  @override
  PaisaColorTokens copyWith({
    Color? backgroundRoot,
    Color? backgroundSurface,
    Color? borderDivider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? brandPrimary,
    Color? brandOnPrimary,
    Color? accentGold,
    Color? accentOnGold,
    Color? stateSuccess,
    Color? stateError,
    Color? stateWarn,
    Color? stateInfo,
    Color? navigationInactive,
    Color? navigationBackground,
  }) {
    return PaisaColorTokens(
      backgroundRoot: backgroundRoot ?? this.backgroundRoot,
      backgroundSurface: backgroundSurface ?? this.backgroundSurface,
      borderDivider: borderDivider ?? this.borderDivider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandOnPrimary: brandOnPrimary ?? this.brandOnPrimary,
      accentGold: accentGold ?? this.accentGold,
      accentOnGold: accentOnGold ?? this.accentOnGold,
      stateSuccess: stateSuccess ?? this.stateSuccess,
      stateError: stateError ?? this.stateError,
      stateWarn: stateWarn ?? this.stateWarn,
      stateInfo: stateInfo ?? this.stateInfo,
      navigationInactive: navigationInactive ?? this.navigationInactive,
      navigationBackground: navigationBackground ?? this.navigationBackground,
    );
  }

  @override
  ThemeExtension<PaisaColorTokens> lerp(
    covariant ThemeExtension<PaisaColorTokens>? other,
    double t,
  ) {
    if (other is! PaisaColorTokens) {
      return this;
    }
    return PaisaColorTokens(
      backgroundRoot: Color.lerp(backgroundRoot, other.backgroundRoot, t)!,
      backgroundSurface:
          Color.lerp(backgroundSurface, other.backgroundSurface, t)!,
      borderDivider: Color.lerp(borderDivider, other.borderDivider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandOnPrimary: Color.lerp(brandOnPrimary, other.brandOnPrimary, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      accentOnGold: Color.lerp(accentOnGold, other.accentOnGold, t)!,
      stateSuccess: Color.lerp(stateSuccess, other.stateSuccess, t)!,
      stateError: Color.lerp(stateError, other.stateError, t)!,
      stateWarn: Color.lerp(stateWarn, other.stateWarn, t)!,
      stateInfo: Color.lerp(stateInfo, other.stateInfo, t)!,
      navigationInactive:
          Color.lerp(navigationInactive, other.navigationInactive, t)!,
      navigationBackground:
          Color.lerp(navigationBackground, other.navigationBackground, t)!,
    );
  }
}
