import 'package:flutter/material.dart';
import 'package:invenman/theme/app_ui.dart';

class AppSortButton<T> extends StatelessWidget {
  final T value;
  final String Function(T value) labelBuilder;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String tooltip;

  const AppSortButton({
    super.key,
    required this.value,
    required this.labelBuilder,
    required this.items,
    required this.onSelected,
    this.icon = Icons.swap_vert_rounded,
    this.tooltip = 'Sort options',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: AppSurfaceCard(
        radius: 20,
        padding: EdgeInsets.zero,
        backgroundColor: cs.surfaceContainerLow,
        child: SizedBox(
          height: double.infinity,
          child: PopupMenuButton<T>(
            tooltip: tooltip,
            initialValue: value,
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: onSelected,
            itemBuilder: (_) => items,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelBuilder(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}