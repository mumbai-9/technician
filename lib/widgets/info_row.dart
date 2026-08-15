import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;
  final double fontSize;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 90,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}
