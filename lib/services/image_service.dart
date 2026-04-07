import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  static const int maxImagesPerItem = 5;
  static const int maxWidth = 1280;
  static const int maxHeight = 720;

  static Future<List<String>> pickAndProcessImages({
    required List<String> existingPaths,
  }) async {
    final remaining = maxImagesPerItem - existingPaths.length;
    if (remaining <= 0) {
      return existingPaths;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return existingPaths;
    }

    final pickedPaths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .take(remaining)
        .toList();

    final processedPaths = <String>[];
    for (final path in pickedPaths) {
      final processed = await _processAndStoreImage(path);
      processedPaths.add(processed);
    }

    return [...existingPaths, ...processedPaths];
  }

  static Future<String> _processAndStoreImage(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Unsupported or corrupted image file.');
    }

    final resized = _resizeIfNeeded(decoded);

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final outPath = p.join(imageDir.path, 'img_$timestamp.jpg');

    final jpgBytes = img.encodeJpg(resized, quality: 85);
    await File(outPath).writeAsBytes(jpgBytes, flush: true);

    return outPath;
  }

  static img.Image _resizeIfNeeded(img.Image source) {
    final width = source.width;
    final height = source.height;

    if (width <= maxWidth && height <= maxHeight) {
      return source;
    }

    final widthRatio = maxWidth / width;
    final heightRatio = maxHeight / height;
    final scale = math.min(widthRatio, heightRatio);

    final targetWidth = math.max(1, (width * scale).round());
    final targetHeight = math.max(1, (height * scale).round());

    return img.copyResize(
      source,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );
  }

  static Future<void> deleteImageFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}