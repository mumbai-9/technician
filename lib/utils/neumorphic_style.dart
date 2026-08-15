import 'package:flutter/material.dart';

class NeumorphicStyle {
  static const Color backgroundColor = Color(0xFFE0E5EC);
  static const Color darkShadow = Color(0xFFA3B1C6);
  static const Color lightShadow = Color(0xFFFFFFFF);

  // Cache commonly used decorations to improve performance
  static final Map<String, BoxDecoration> _decorationCache = {};

  static BoxDecoration neumorphicDecoration({
    bool isPressed = false,
    double borderRadius = 12,
    Color? color,
  }) {
    final key = 'neuro_${isPressed}_${borderRadius}_${color?.toARGB32() ?? 0}';

    if (_decorationCache.containsKey(key)) {
      return _decorationCache[key]!;
    }

    final decoration = BoxDecoration(
      color: color ?? backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              const BoxShadow(
                color: Color(0x80A3B1C6),
                offset: Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              const BoxShadow(
                color: Color(0xCCFFFFFF),
                offset: Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ]
          : [
              const BoxShadow(
                color: Color(0x80A3B1C6),
                offset: Offset(8, 8),
                blurRadius: 16,
                spreadRadius: 0,
              ),
              const BoxShadow(
                color: Color(0xE6FFFFFF),
                offset: Offset(-8, -8),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
    );

    _decorationCache[key] = decoration;
    return decoration;
  }

  static BoxDecoration neumorphicInsetDecoration({
    double borderRadius = 12,
    Color? color,
  }) {
    final key = 'inset_${borderRadius}_${color?.toARGB32() ?? 0}';

    if (_decorationCache.containsKey(key)) {
      return _decorationCache[key]!;
    }

    final decoration = BoxDecoration(
      color: color ?? backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x80A3B1C6),
          offset: Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Color(0xCCFFFFFF),
          offset: Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );

    _decorationCache[key] = decoration;
    return decoration;
  }

  static BoxDecoration coloredNeumorphicDecoration({
    required Color color,
    bool isPressed = false,
    double borderRadius = 12,
  }) {
    final key = 'colored_${color.toARGB32()}_${isPressed}_$borderRadius';

    if (_decorationCache.containsKey(key)) {
      return _decorationCache[key]!;
    }

    final darkColor = Color.lerp(color, Colors.black, 0.2)!;
    final lightColor = Color.lerp(color, Colors.white, 0.2)!;

    final decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: darkColor.withValues(alpha: 0.6),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: lightColor.withValues(alpha: 0.6),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: darkColor.withValues(alpha: 0.6),
                offset: const Offset(6, 6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: lightColor.withValues(alpha: 0.6),
                offset: const Offset(-6, -6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
    );

    _decorationCache[key] = decoration;
    return decoration;
  }

  // Clear cache if needed (call when memory is low)
  static void clearCache() {
    _decorationCache.clear();
  }
}

// Responsive helper class
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSize * 0.9;
    } else if (width > 600) {
      return baseSize * 1.1;
    }
    return baseSize;
  }

  static double getResponsivePadding(BuildContext context, double basePadding) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return basePadding * 0.8;
    } else if (width > 600) {
      return basePadding * 1.2;
    }
    return basePadding;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.all(12);
    } else if (width > 600) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }

  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1024) {
      return 800; // Desktop
    } else if (width > 600) {
      return width * 0.8; // Tablet
    }
    return width; // Mobile
  }
}
