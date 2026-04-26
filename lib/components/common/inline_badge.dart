import 'package:flutter/material.dart';

class InlineBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;

  const InlineBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}