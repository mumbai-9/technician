import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.grey[800], size: 24),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
