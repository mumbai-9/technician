import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final EdgeInsets? margin;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration:
          NeumorphicStyle.neumorphicDecoration(borderRadius: borderRadius),
      child: child,
    );
  }
}

class NeumorphicInsetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final EdgeInsets? margin;

  const NeumorphicInsetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration:
          NeumorphicStyle.neumorphicInsetDecoration(borderRadius: borderRadius),
      child: child,
    );
  }
}
