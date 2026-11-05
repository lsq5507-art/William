import 'package:flutter/material.dart';

/// Little Paw Premium tokens (LP-DS01 §8 / LP-D-09).
@immutable
class LpTokens extends ThemeExtension<LpTokens> {
  final Color bgPage;
  final Color bgMuted;
  final Color textSecondary;
  final Color textTertiary;
  final Color brandSoft;
  final Color like;
  final Color ringUnreadStart;
  final Color ringUnreadEnd;
  final Color ringRead;
  final Color chatBubbleMe;
  final Color chatBubbleThem;
  final Color chatBubbleSystem;
  final Color ctaInverse;
  final Color onCtaInverse;
  final Color borderHairline;
  final double space1;
  final double space2;
  final double radiusMd;
  final double radiusLg;
  final double hitMin;
  final double elevCardBlur;

  const LpTokens({
    required this.bgPage,
    required this.bgMuted,
    required this.textSecondary,
    required this.textTertiary,
    required this.brandSoft,
    required this.like,
    required this.ringUnreadStart,
    required this.ringUnreadEnd,
    required this.ringRead,
    required this.chatBubbleMe,
    required this.chatBubbleThem,
    required this.chatBubbleSystem,
    required this.ctaInverse,
    required this.onCtaInverse,
    required this.borderHairline,
    required this.space1,
    required this.space2,
    required this.radiusMd,
    required this.radiusLg,
    required this.hitMin,
    required this.elevCardBlur,
  });

  static const light = LpTokens(
    bgPage: Color(0xFFF4F2EF),
    bgMuted: Color(0xFFECEAE6),
    textSecondary: Color(0xFF6B6B6B),
    textTertiary: Color(0xFF8A8A8A),
    brandSoft: Color(0xFFF3E0D4),
    like: Color(0xFFD11F4F),
    ringUnreadStart: Color(0xFFE07A3A),
    ringUnreadEnd: Color(0xFFD889A8),
    ringRead: Color(0xFFC8C4BE),
    chatBubbleMe: Color(0xFF1A1A1A),
    chatBubbleThem: Color(0xFFECEAE6),
    chatBubbleSystem: Color(0xFFF4F2EF),
    ctaInverse: Color(0xFF1A1A1A),
    onCtaInverse: Color(0xFFFFFFFF),
    borderHairline: Color(0xFFE4E1DC),
    space1: 8,
    space2: 16,
    radiusMd: 16,
    radiusLg: 20,
    hitMin: 44,
    elevCardBlur: 0,
  );

  @override
  LpTokens copyWith({
    Color? bgPage,
    Color? bgMuted,
    Color? textSecondary,
    Color? textTertiary,
    Color? brandSoft,
    Color? like,
    Color? ringUnreadStart,
    Color? ringUnreadEnd,
    Color? ringRead,
    Color? chatBubbleMe,
    Color? chatBubbleThem,
    Color? chatBubbleSystem,
    Color? ctaInverse,
    Color? onCtaInverse,
    Color? borderHairline,
    double? space1,
    double? space2,
    double? radiusMd,
    double? radiusLg,
    double? hitMin,
    double? elevCardBlur,
  }) {
    return LpTokens(
      bgPage: bgPage ?? this.bgPage,
      bgMuted: bgMuted ?? this.bgMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brandSoft: brandSoft ?? this.brandSoft,
      like: like ?? this.like,
      ringUnreadStart: ringUnreadStart ?? this.ringUnreadStart,
      ringUnreadEnd: ringUnreadEnd ?? this.ringUnreadEnd,
      ringRead: ringRead ?? this.ringRead,
      chatBubbleMe: chatBubbleMe ?? this.chatBubbleMe,
      chatBubbleThem: chatBubbleThem ?? this.chatBubbleThem,
      chatBubbleSystem: chatBubbleSystem ?? this.chatBubbleSystem,
      ctaInverse: ctaInverse ?? this.ctaInverse,
      onCtaInverse: onCtaInverse ?? this.onCtaInverse,
      borderHairline: borderHairline ?? this.borderHairline,
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      hitMin: hitMin ?? this.hitMin,
      elevCardBlur: elevCardBlur ?? this.elevCardBlur,
    );
  }

  @override
  LpTokens lerp(ThemeExtension<LpTokens>? other, double t) {
    if (other is! LpTokens) return this;
    return LpTokens(
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      bgMuted: Color.lerp(bgMuted, other.bgMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      like: Color.lerp(like, other.like, t)!,
      ringUnreadStart: Color.lerp(ringUnreadStart, other.ringUnreadStart, t)!,
      ringUnreadEnd: Color.lerp(ringUnreadEnd, other.ringUnreadEnd, t)!,
      ringRead: Color.lerp(ringRead, other.ringRead, t)!,
      chatBubbleMe: Color.lerp(chatBubbleMe, other.chatBubbleMe, t)!,
      chatBubbleThem: Color.lerp(chatBubbleThem, other.chatBubbleThem, t)!,
      chatBubbleSystem:
          Color.lerp(chatBubbleSystem, other.chatBubbleSystem, t)!,
      ctaInverse: Color.lerp(ctaInverse, other.ctaInverse, t)!,
      onCtaInverse: Color.lerp(onCtaInverse, other.onCtaInverse, t)!,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      space1: space1 + (other.space1 - space1) * t,
      space2: space2 + (other.space2 - space2) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      radiusLg: radiusLg + (other.radiusLg - radiusLg) * t,
      hitMin: hitMin + (other.hitMin - hitMin) * t,
      elevCardBlur: elevCardBlur + (other.elevCardBlur - elevCardBlur) * t,
    );
  }
}

/// G-01: dismiss / cancel / later — weak Secondary, never unlock filled primary.
ButtonStyle lpSecondaryCtaStyle({
  Color foreground = const Color(0xFF1A1A1A),
  Color outline = const Color(0xFFE4E1DC),
  bool outlined = true,
}) {
  if (!outlined) {
    return TextButton.styleFrom(
      foregroundColor: foreground,
      minimumSize: const Size(44, 44),
    );
  }
  return OutlinedButton.styleFrom(
    foregroundColor: foreground,
    side: BorderSide(color: outline),
    minimumSize: const Size(44, 44),
  );
}

ButtonStyle lpPrimaryCtaStyle({
  Color background = const Color(0xFF1A1A1A),
  Color foreground = const Color(0xFFFFFFFF),
  double radius = 12,
}) {
  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: foreground,
    disabledBackgroundColor: const Color(0xFFBBBBBB),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

abstract final class LpTheme {
  static const Color brandPrimary = Color(0xFFC45C26);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color bgElevated = Color(0xFFFFFFFF);

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: brandPrimary,
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF2E7D4F),
        onSecondary: Color(0xFFFFFFFF),
        surface: bgElevated,
        onSurface: textPrimary,
        surfaceContainerHighest: Color(0xFFECEAE6),
        outline: Color(0xFFE4E1DC),
        error: Color(0xFFB42318),
        onError: Color(0xFFFFFFFF),
      );

  static TextTheme get lightTextTheme => const TextTheme(
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.35,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.3,
          color: Color(0xFF6B6B6B),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 1.3,
          color: Color(0xFF8A8A8A),
        ),
      );

  static ThemeData light() {
    final scheme = lightColorScheme;
    const tokens = LpTokens.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgPage,
      textTheme: lightTextTheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: const AppBarTheme(
        backgroundColor: bgElevated,
        foregroundColor: textPrimary,
        surfaceTintColor: bgElevated,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgElevated,
        indicatorColor: tokens.brandSoft,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: textPrimary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? textPrimary : tokens.textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: bgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          side: BorderSide(color: tokens.borderHairline),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: lpPrimaryCtaStyle(),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: lpSecondaryCtaStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: lpSecondaryCtaStyle(outlined: false),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: bgElevated,
        foregroundColor: textPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.borderHairline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.borderHairline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bgElevated,
        surfaceTintColor: bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusLg),
          ),
        ),
      ),
    );
  }
}

extension LpTokensX on BuildContext {
  LpTokens get lpTokens =>
      Theme.of(this).extension<LpTokens>() ?? LpTokens.light;
}
