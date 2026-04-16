import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:invenman/services/db_services.dart';
import 'package:invenman/theme/app_ui.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const SettingsScreen({
    super.key,
    this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appName = 'InvenMan';

  bool _busy = false;

  Future<void> _exportData() async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export InvenMan database',
      fileName: 'invenman_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db'],
    );

    if (savePath == null || savePath.trim().isEmpty) return;

    await _runBusy(() async {
      await DBHelper.exportDatabaseToPath(savePath);

      if (!mounted) return;
      _showSnackBar('Database exported successfully.');
    });
  }

  Future<void> _importData() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import InvenMan database',
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db'],
      allowMultiple: false,
      withData: false,
    );

    final path = picked?.files.single.path;
    if (path == null || path.trim().isEmpty) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Import data?'),
              content: const Text(
                'This will append records from the selected backup into this device\'s current database.\n\n'
                'Old backups are upgraded automatically before import.\n'
                'Image/document file paths that do not exist on this device are skipped.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Import'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await _runBusy(() async {
      final summary = await DBHelper.importDatabaseFromPath(path);

      widget.onDataChanged?.call();

      if (!mounted) return;
      _showSnackBar(
        'Imported ${summary.totalRowsInserted} rows '
        '(${summary.itemsInserted} items, '
        '${summary.salesInserted} sales, '
        '${summary.installmentPlansInserted} plans, '
        '${summary.installmentPaymentsInserted} payments, '
        '${summary.historyInserted} history).',
      );
    });
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    await _runBusy(() async {
      await DBHelper.deleteAllAppData();

      widget.onDataChanged?.call();

      if (!mounted) return;
      _showSnackBar('All local app data has been deleted.');
    });
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final matches = controller.text.trim() == _appName;

            return AlertDialog(
              title: const Text('Delete all local data?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes all local inventory, sales, installments, history, and stored image/document files from this device.',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type $_appName to continue.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'App name',
                      hintText: 'InvenMan',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: matches
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: const Text('Delete everything'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result ?? false;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppUi.pageHPadding,
            12,
            AppUi.pageHPadding,
            AppUi.pageBottomPadding,
          ),
          children: [
            AppSectionCard(
              title: 'Data management',
              subtitle:
                  'Export, import, or wipe local app data stored on this device.',
              child: Column(
                children: [
                  _SettingsActionTile(
                    icon: Icons.ios_share_rounded,
                    title: 'Export database',
                    subtitle:
                        'Save a SQLite backup file to a location you choose.',
                    onTap: _busy ? null : _exportData,
                  ),
                  const SizedBox(height: 12),
                  _SettingsActionTile(
                    icon: Icons.download_rounded,
                    title: 'Import database',
                    subtitle:
                        'Append records from a previously exported SQLite backup.',
                    onTap: _busy ? null : _importData,
                  ),
                  const SizedBox(height: 12),
                  _SettingsActionTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete all local data',
                    subtitle:
                        'Erase inventory, sales, installments, history, and stored files from this device.',
                    danger: true,
                    onTap: _busy ? null : _deleteAllData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppSurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current export/import is database-only. Since your app stores image/document files separately from SQLite, missing file paths are ignored during import if those files do not exist on this device.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = danger ? cs.error : cs.primary;
    final titleColor = danger ? cs.error : cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.innerRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppUi.innerRadius),
            border: Border.all(
              color: danger ? cs.error.withOpacity(0.22) : cs.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: danger
                        ? cs.errorContainer.withOpacity(0.8)
                        : cs.primaryContainer.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}