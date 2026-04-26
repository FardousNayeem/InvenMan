import 'package:flutter/material.dart';

import 'package:invenman/components/common/sensitive_value_text.dart';

class MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? valueText;
  final String? sensitiveText;
  final bool isSensitive;
  final Color? valueColor;

  const MetricChip({
    super.key,
    required this.icon,
    required this.label,
    this.valueText,
    this.sensitiveText,
    this.isSensitive = false,
    this.valueColor,
  }) : assert(valueText != null || sensitiveText != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          if (isSensitive)
            SensitiveValueText(
              visibleText: sensitiveText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor ?? cs.onSurface,
              ),
            )
          else
            Text(
              valueText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor ?? cs.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}