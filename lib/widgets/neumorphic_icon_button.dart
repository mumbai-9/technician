import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final double borderRadius;
  final EdgeInsets padding;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 24,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Icon(
              icon,
              color: Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
