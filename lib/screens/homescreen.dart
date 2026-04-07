import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:invenman/main.dart';
import 'package:invenman/screens/historyscreen.dart';
import 'package:invenman/screens/installmentsscreen.dart';
import 'package:invenman/screens/inventoryscreen.dart';
import 'package:invenman/screens/salesscreen.dart';
import 'package:invenman/theme/app_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _refreshToken = 0;

  void _handleDataChanged() {
    setState(() {
      _refreshToken++;
    });
  }

  _PageMeta get _pageMeta {
    switch (_currentIndex) {
      case 0:
        return const _PageMeta(
          title: 'Inventory',
          subtitle: 'Stock, sourcing, pricing, and product records',
          icon: Icons.inventory_2_rounded,
        );
      case 1:
        return const _PageMeta(
          title: 'Sales',
          subtitle: 'Transactions, buyers, payment type, and warranty snapshots',
          icon: Icons.point_of_sale_rounded,
        );
      case 2:
        return const _PageMeta(
          title: 'Installments',
          subtitle: 'Due dates, balances, monthly progress, and overdue plans',
          icon: Icons.calendar_month_rounded,
        );
      case 3:
      default:
        return const _PageMeta(
          title: 'History',
          subtitle: 'Every addition, edit, sale, deletion, and payment trail',
          icon: Icons.history_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final privacyProvider = context.watch<PrivacyProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final hideSensitive = privacyProvider.hideSensitiveValues;
    final cs = Theme.of(context).colorScheme;

    final screens = [
      InventoryPage(onDataChanged: _handleDataChanged),
      SalesPage(refreshToken: _refreshToken),
      InstallmentsPage(refreshToken: _refreshToken),
      HistoryPage(refreshToken: _refreshToken),
    ];

    final pageMeta = _pageMeta;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey(_currentIndex),
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(
                  pageMeta.icon,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageMeta.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      pageMeta.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.2,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppUi.softShadow,
              ),
              child: IconButton.filledTonal(
                tooltip: hideSensitive
                    ? 'Show sensitive values'
                    : 'Hide sensitive values',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                ),
                onPressed: () async {
                  final wasHidden = hideSensitive;
                  await privacyProvider.toggleSensitiveVisibility();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasHidden
                            ? 'Sensitive values are now visible.'
                            : 'Sensitive values are now hidden.',
                      ),
                    ),
                  );
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    hideSensitive
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    key: ValueKey(hideSensitive),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppUi.softShadow,
              ),
              child: IconButton.filledTonal(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppUi.shellShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 220),
              onDestinationSelected: (index) {
                if (_currentIndex == index) return;
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: 'Sales',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Installments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageMeta {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PageMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}