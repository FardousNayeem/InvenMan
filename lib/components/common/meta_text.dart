import 'package:flutter/material.dart';

class MetaText extends StatelessWidget {
  final String label;
  final String value;

  const MetaText({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 11.8,
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}