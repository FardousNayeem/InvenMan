import 'package:flutter/material.dart';

class AppTopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const AppTopBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTopBarAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AppTopBarAddButton({
    super.key,
    required this.onPressed,
    this.label = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}