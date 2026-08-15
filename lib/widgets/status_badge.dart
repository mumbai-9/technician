import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class StatusBadgeInset extends StatelessWidget {
  final String text;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;

  const StatusBadgeInset({
    super.key,
    required this.text,
    required this.textColor,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration:
          NeumorphicStyle.neumorphicInsetDecoration(borderRadius: borderRadius),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
