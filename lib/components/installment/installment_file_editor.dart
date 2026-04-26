import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invenman/services/media/image_service.dart';

class InstallmentDocumentEditorDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> initialPaths;
  final Future<void> Function(List<String> imagePaths) onSave;

  const InstallmentDocumentEditorDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialPaths,
    required this.onSave,
  });

  @override
  State<InstallmentDocumentEditorDialog> createState() =>
      _InstallmentDocumentEditorDialogState();
}

class _InstallmentDocumentEditorDialogState
    extends State<InstallmentDocumentEditorDialog> {
  late List<String> _paths;
  bool _isSaving = false;

  late final List<String> _initialPaths;
  final Set<String> _newPaths = {};
  final Set<String> _removedExistingPaths = {};
  bool _didCommitChanges = false;

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.initialPaths);
    _initialPaths = List<String>.from(_paths);
  }

  @override
  void dispose() {
    if (!_didCommitChanges && _newPaths.isNotEmpty) {
      unawaited(ImageService.deleteImageFiles(_newPaths));
    }

    super.dispose();
  }

  Future<void> _pickMore() async {
    try {
      final before = _paths.toSet();

      final picked = await ImageService.pickAndProcessInstallmentImages(
        existingPaths: _paths,
        context: context,
      );

      if (!mounted) return;

      final limited = picked.take(5).toList();
      final addedPaths = limited.where((path) => !before.contains(path));

      setState(() {
        _paths = limited;
        _newPaths.addAll(addedPaths);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add documents: $e')),
      );
    }
  }

  Future<void> _removePath(String path) async {
    setState(() {
      _paths.remove(path);
    });

    if (_newPaths.remove(path)) {
      await ImageService.deleteImageFile(path);
      return;
    }

    if (_initialPaths.contains(path)) {
      _removedExistingPaths.add(path);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave(_paths);

      final deletedPaths = _removedExistingPaths.where(
        (path) => !_paths.contains(path),
      );

      await ImageService.deleteImageFiles(deletedPaths);

      _didCommitChanges = true;
      _newPaths.clear();
      _removedExistingPaths.clear();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _paths.length >= 5 || _isSaving ? null : _pickMore,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text('Add (${_paths.length}/5)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_paths.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'No installment documents added yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _paths.map((path) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 104,
                            height: 104,
                            color: cs.surfaceContainerHighest,
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.broken_image_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: _isSaving ? null : () => _removePath(path),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Text('Save documents'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}