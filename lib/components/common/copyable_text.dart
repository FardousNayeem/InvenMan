import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const CopyableText({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 90,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '—' : value;

    return GestureDetector(
      onTap: value.trim().isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              }
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (value.trim().isNotEmpty)
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}