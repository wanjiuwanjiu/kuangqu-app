import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 设计令牌：对标网页版 iOS 原生风格
/// 极简纯净、大面积留白、低饱和天蓝、连续圆角、柔和阴影
class AppColors {
  AppColors._();

  /// 低饱和天蓝主色
  static const Color primary = Color(0xFF5BA4E6);
  static const Color primaryDark = Color(0xFF4A8FD4);

  // 浅色
  static const Color lightBg = Color(0xFFF7F8FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightSubText = Color(0xFF8E8E93);
  static const Color lightDivider = Color(0xFFECECF0);

  // 深色
  static const Color darkBg = Color(0xFF0E0E10);
  static const Color darkCard = Color(0xFF1B1B1E);
  static const Color darkText = Color(0xFFF2F2F7);
  static const Color darkSubText = Color(0xFF9A9AA0);
  static const Color darkDivider = Color(0xFF2A2A2E);

  static const Color danger = Color(0xFFFF5A5A);
}

class AppRadius {
  AppRadius._();
  static const double card = 16;
  static const double button = 14;
  static const double input = 12;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        card: AppColors.lightCard,
        text: AppColors.lightText,
        subText: AppColors.lightSubText,
        divider: AppColors.lightDivider,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        text: AppColors.darkText,
        subText: AppColors.darkSubText,
        divider: AppColors.darkDivider,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color text,
    required Color subText,
    required Color divider,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: card,
      onSurface: text,
      surfaceContainerHighest: bg,
      outline: divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: bg.withValues(alpha: 0.85),
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 0.5),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: TextStyle(color: subText, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: divider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: text, fontSize: 15, height: 1.45),
        bodySmall: TextStyle(color: subText, fontSize: 13, height: 1.4),
        titleLarge: TextStyle(
            color: text, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
            color: text, fontSize: 17, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: subText, fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // 柔和的右滑切换，贴近 iOS 原生
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 柔和卡片阴影（浅色模式下提升层次感）
List<BoxShadow> softShadow(Brightness brightness) => [
      BoxShadow(
        color: brightness == Brightness.light
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
