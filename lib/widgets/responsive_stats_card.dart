import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class ResponsiveStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ResponsiveStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 14 : 20,
        horizontal: isSmallScreen ? 6 : 12,
      ),
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: isSmallScreen ? 10 : 14,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
