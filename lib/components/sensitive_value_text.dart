import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invenman/main.dart';

class SensitiveValueText extends StatelessWidget {
  final String visibleText;
  final TextStyle? style;
  final String hiddenText;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const SensitiveValueText({
    super.key,
    required this.visibleText,
    this.style,
    this.hiddenText = '•••••',
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final hideSensitive = context.watch<PrivacyProvider>().hideSensitiveValues;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Text(
        hideSensitive ? hiddenText : visibleText,
        key: ValueKey('${hideSensitive}_$visibleText'),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}