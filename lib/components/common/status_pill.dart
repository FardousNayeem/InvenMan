import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final EdgeInsetsGeometry padding;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.4,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}