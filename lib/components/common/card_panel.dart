import 'package:flutter/material.dart';

class CardPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  const CardPanel({
    super.key,
    required this.title,
    required this.child,
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: padding ?? EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha:0.78),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.45,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}