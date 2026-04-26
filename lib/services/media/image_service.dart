import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AppImageType {
  product,
  installment,
}

class ImageService {
  static const int maxImagesPerSet = 5;
  static const int _maxDimension = 1600;
  static const int _jpgQuality = 88;
  static int _fileSequence = 0;

  static Future<List<String>> pickAndProcessImages({
    required List<String> existingPaths,
    BuildContext? context,
    AppImageType type = AppImageType.product,
  }) async {
    final existing = List<String>.from(existingPaths);

    if (existing.length >= maxImagesPerSet) {
      throw Exception('Maximum $maxImagesPerSet images allowed.');
    }

    final remaining = maxImagesPerSet - existing.length;
    final files = await _pickSourceFiles(
      context: context,
      remaining: remaining,
      type: type,
    );

    if (files.isEmpty) return existing;

    final processed = <String>[...existing];

    for (final file in files) {
      final savedPath = await _processAndSaveImage(
        File(file.path),
        type: type,
      );
      processed.add(savedPath);
    }

    return processed.take(maxImagesPerSet).toList();
  }

  static Future<List<String>> pickAndProcessProductImages({
    required List<String> existingPaths,
    BuildContext? context,
  }) {
    return pickAndProcessImages(
      existingPaths: existingPaths,
      context: context,
      type: AppImageType.product,
    );
  }

  static Future<List<String>> pickAndProcessInstallmentImages({
    required List<String> existingPaths,
    required BuildContext context,
  }) {
    return pickAndProcessImages(
      existingPaths: existingPaths,
      context: context,
      type: AppImageType.installment,
    );
  }

  static Future<void> deleteImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<List<XFile>> _pickSourceFiles({
    required BuildContext? context,
    required int remaining,
    required AppImageType type,
  }) async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      final picker = ImagePicker();

      ImageSource? source;
      if (context != null && type == AppImageType.installment) {
        source = await _showMobileSourceSheet(context);
      } else {
        source = ImageSource.gallery;
      }

      if (source == null) return const [];

      if (source == ImageSource.camera) {
        final photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 95,
        );
        return photo == null ? const [] : [photo];
      }

      final galleryPhotos = await picker.pickMultiImage(
        imageQuality: 95,
      );

      if (galleryPhotos.isEmpty) return const [];
      return galleryPhotos.take(remaining).toList();
    }

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: remaining > 1,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return const [];

    return result.files
        .where((file) => file.path != null)
        .take(remaining)
        .map((file) => XFile(file.path!))
        .toList();
  }

  static Future<ImageSource?> _showMobileSourceSheet(
    BuildContext context,
  ) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<String> _processAndSaveImage(
    File inputFile, {
    required AppImageType type,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not read selected image.');
    }

    final resized = _resizePreservingAspect(decoded);
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: _jpgQuality),
    );

    final saveDir = await _getImageDirectory(type);
    final fileName = _buildFileName(type);
    final outputPath = p.join(saveDir.path, fileName);

    final outFile = File(outputPath);
    await outFile.writeAsBytes(encoded, flush: true);
    return outputPath;
  }

  static img.Image _resizePreservingAspect(img.Image source) {
    if (source.width <= _maxDimension && source.height <= _maxDimension) {
      return source;
    }

    if (source.width >= source.height) {
      return img.copyResize(source, width: _maxDimension);
    }

    return img.copyResize(source, height: _maxDimension);
  }

  static Future<Directory> _getImageDirectory(AppImageType type) async {
    final baseDir = await getApplicationSupportDirectory();
    final folderName =
        type == AppImageType.product ? 'product_images' : 'installment_images';

    final dir = Directory(p.join(baseDir.path, 'invenman', folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _buildFileName(AppImageType type) {
    final prefix = type == AppImageType.product ? 'product' : 'installment';
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _fileSequence = (_fileSequence + 1) % 100000;
    return '${prefix}_${timestamp}_$_fileSequence.jpg';
  }

  static Future<void> deleteImageFiles(Iterable<String> paths) async {
    for (final path in paths) {
      await deleteImageFile(path);
    }
  }

  static Future<Directory> getAppRootDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'invenman'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> getImageDirectory(AppImageType type) {
    return _getImageDirectory(type);
  }

  static Future<String> importBackupImage({
    required File sourceFile,
    required AppImageType type,
  }) async {
    final targetDir = await _getImageDirectory(type);
    final targetPath = p.join(targetDir.path, _buildFileName(type));
    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }
}