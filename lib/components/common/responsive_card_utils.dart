import 'package:flutter/material.dart';

class ResponsiveCardUtils {
  const ResponsiveCardUtils._();

  static bool isCompact(BuildContext context, {double breakpoint = 760}) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  static EdgeInsets cardPadding(BuildContext context) {
    return isCompact(context)
        ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
        : const EdgeInsets.fromLTRB(16, 14, 16, 14);
  }

  static double visualSize(BuildContext context) {
    return isCompact(context) ? 84 : 102;
  }

  static double titleFontSize(BuildContext context) {
    return isCompact(context) ? 18.8 : 20.5;
  }

  static double horizontalGap(BuildContext context) {
    return isCompact(context) ? 12 : 16;
  }

  static double sectionGap(BuildContext context) {
    return isCompact(context) ? 10 : 14;
  }
}

class ResponsiveChipWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const ResponsiveChipWrap({
    super.key,
    required this.children,
    this.spacing = 10,
    this.runSpacing = 10,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}