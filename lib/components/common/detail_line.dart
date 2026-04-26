import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:invenman/app/providers/privacy_provider.dart';
import 'package:invenman/components/common/sensitive_value_text.dart';

class DetailLine extends StatelessWidget {
  final String label;
  final String? value;
  final String? sensitiveValue;
  final bool isSensitive;
  final Color? valueColor;
  final bool multiline;
  final double labelMinWidth;

  const DetailLine({
    super.key,
    required this.label,
    this.value,
    this.sensitiveValue,
    this.isSensitive = false,
    this.valueColor,
    this.multiline = false,
    this.labelMinWidth = 56,
  }) : assert(value != null || sensitiveValue != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hideSensitive = context.watch<PrivacyProvider>().hideSensitiveValues;

    if (isSensitive && hideSensitive) {
      return Text(
        '••••',
        style: TextStyle(
          fontSize: 13.4,
          height: 1.4,
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final textWidget = isSensitive
        ? SensitiveValueText(
            visibleText: sensitiveValue!,
            style: TextStyle(
              fontSize: 13.4,
              height: 1.4,
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          )
        : Text(
            value!,
            style: TextStyle(
              fontSize: 13.4,
              height: 1.4,
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          );

    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: labelMinWidth),
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (multiline)
          Expanded(child: textWidget)
        else
          Flexible(child: textWidget),
      ],
    );
  }
}