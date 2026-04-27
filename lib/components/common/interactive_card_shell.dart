import 'package:flutter/material.dart';

class InteractiveCardShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double pressedScale;
  final EdgeInsetsGeometry? margin;

  const InteractiveCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 28,
    this.pressedScale = 0.992,
    this.margin,
  });

  @override
  State<InteractiveCardShell> createState() => _InteractiveCardShellState();
}

class _InteractiveCardShellState extends State<InteractiveCardShell> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = _pressed ? widget.pressedScale : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: scale,
        child: Container(
          margin: widget.margin,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _hovered
                        ? cs.primary.withValues(alpha:0.22)
                        : cs.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: _hovered ? 22 : 18,
                      offset: Offset(0, _hovered ? 10 : 8),
                      color: Colors.black.withValues(alpha:
                        _hovered ? 0.07 : 0.05,
                      ),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}