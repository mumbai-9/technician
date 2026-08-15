import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NeumorphicButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final bool fullWidth;

  const NeumorphicButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
