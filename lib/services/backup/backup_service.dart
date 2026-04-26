import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/history.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/models/backup_models.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';

class BackupService {
  const BackupService._();

  static const String _backupManifestFileName = 'manifest.json';
  static const String _backupDatabaseFileName = 'database.sqlite';
  static const int _backupFormatVersion = 1;
  static int _importAssetSequence = 0;
  
  static Map<String, dynamic> _withoutId(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.remove('id');
    return copy;
  }

  static Future<void> _deleteDirectoryIfExists(Directory dir) async {
    if (!await dir.exists()) return;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        return;
      } on FileSystemException {
        if (attempt == 5) rethrow;
        await Future.delayed(Duration(milliseconds: 120 * (attempt + 1)));
      }
    }
  }

  static Future<Directory> _makeUniqueTempDir(
    String prefix, {
    bool createNow = true,
  }) async {
    final tempDir = await getTemporaryDirectory();

    for (var i = 0; i < 1000; i++) {
      final suffix = '${DateTime.now().microsecondsSinceEpoch}_$i';
      final dir = Directory(p.join(tempDir.path, '${prefix}_$suffix'));

      if (!await dir.exists()) {
        if (createNow) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    }

    throw Exception('Could not allocate a temporary working directory.');
  }

  static Future<void> _extractArchiveManually(
    Archive archive,
    String outputPath,
  ) async {
    final root = Directory(outputPath);

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    for (final entry in archive) {
      final safeName = entry.name.replaceAll('\\', '/').trim();
      if (safeName.isEmpty) continue;

      if (safeName.startsWith('/') || safeName.contains('../')) {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }

      final outPath = p.join(outputPath, safeName);

      if (entry.isFile) {
        final outFile = File(outPath);

        if (!await outFile.parent.exists()) {
          await outFile.parent.create(recursive: true);
        }

        final data = entry.content;

        await outFile.writeAsBytes(data, flush: true);
            } else {
        final outDir = Directory(outPath);

        if (!await outDir.exists()) {
          await outDir.create(recursive: true);
        }
      }
    }
  }

  static String _inferAssetKindFromPath(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();

    if (normalized.contains('/installment_images/')) {
      return 'installment';
    }

    return 'product';
  }

  static String _assetFolderNameForKind(String kind) {
    return kind == 'installment'
        ? 'assets/installment_images'
        : 'assets/product_images';
  }

  static String _buildUniqueArchiveAssetPath({
    required String folderName,
    required String originalPath,
    required Set<String> usedArchivePaths,
  }) {
    final extRaw = p.extension(originalPath);
    final ext = extRaw.isEmpty ? '.jpg' : extRaw;

    final base = p
        .basenameWithoutExtension(originalPath)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .trim();

    final safeBase = base.isEmpty ? 'asset' : base;

    var candidate = '$folderName/$safeBase$ext';
    var counter = 1;

    while (usedArchivePaths.contains(candidate)) {
      candidate = '$folderName/${safeBase}_$counter$ext';
      counter++;
    }

    usedArchivePaths.add(candidate);
    return candidate;
  }

  static Future<File> exportDatabaseToPath(String destinationPath) async {
    final dbClient = await AppDatabase.db;
    final outFile = File(destinationPath);

    if (!await outFile.parent.exists()) {
      await outFile.parent.create(recursive: true);
    }

    if (await outFile.exists()) {
      await outFile.delete();
    }

    final escapedPath = destinationPath.replaceAll("'", "''");

    try {
      await dbClient.execute('PRAGMA wal_checkpoint(FULL)');
      await dbClient.execute("VACUUM INTO '$escapedPath'");
      return outFile;
    } catch (_) {
      final sourcePath = await AppDatabase.getDatabasePath();
      await AppDatabase.close();

      try {
        final sourceFile = File(sourcePath);
        await sourceFile.copy(destinationPath);
      } finally {
        await AppDatabase.db;
      }

      return outFile;
    }
  }

  static Future<List<BackupAssetManifestEntry>>
      _collectBackupAssetEntries() async {
    final dbClient = await AppDatabase.db;

    final usedArchivePaths = <String>{};
    final seenOriginalPaths = <String>{};
    final entries = <BackupAssetManifestEntry>[];

    Future<void> addPaths(List<String> paths) async {
      for (final rawPath in paths) {
        final path = rawPath.trim();

        if (path.isEmpty || seenOriginalPaths.contains(path)) continue;

        final file = File(path);
        if (!await file.exists()) continue;

        seenOriginalPaths.add(path);

        final kind = _inferAssetKindFromPath(path);
        final archivePath = _buildUniqueArchiveAssetPath(
          folderName: _assetFolderNameForKind(kind),
          originalPath: path,
          usedArchivePaths: usedArchivePaths,
        );

        entries.add(
          BackupAssetManifestEntry(
            originalPath: path,
            archivePath: archivePath,
            kind: kind,
          ),
        );
      }
    }

    final itemRows = await dbClient.query('items');
    for (final row in itemRows) {
      final item = Item.fromMap(row);
      await addPaths(item.imagePaths);
    }

    final saleRows = await dbClient.query('sale_records');
    for (final row in saleRows) {
      final sale = SaleRecord.fromMap(row);
      await addPaths(sale.installmentImagePaths);
    }

    final planRows = await dbClient.query('installment_plans');
    for (final row in planRows) {
      final plan = InstallmentPlan.fromMap(row);
      await addPaths(plan.installmentImagePaths);
    }

    return entries;
  }

  static Future<File> exportBackupPackageToPath(String destinationPath) async {
    final workDir = await _makeUniqueTempDir('invenman_export');

    try {
      final dbSnapshotPath = p.join(workDir.path, _backupDatabaseFileName);
      await exportDatabaseToPath(dbSnapshotPath);

      final assetEntries = await _collectBackupAssetEntries();

      final manifest = BackupManifest(
        app: 'InvenMan',
        backupVersion: _backupFormatVersion,
        createdAt: DbShared.nowUtc().toIso8601String(),
        databaseFile: _backupDatabaseFileName,
        dbSchemaVersion: AppDatabase.databaseVersion,
        assets: assetEntries,
      );

      final manifestFile = File(
        p.join(workDir.path, _backupManifestFileName),
      );

      await manifestFile.writeAsString(
        jsonEncode(manifest.toMap()),
        flush: true,
      );

      final archive = Archive();

      final dbFile = File(dbSnapshotPath);
      archive.addFile(
        ArchiveFile(
          _backupDatabaseFileName,
          await dbFile.length(),
          await dbFile.readAsBytes(),
        ),
      );

      archive.addFile(
        ArchiveFile(
          _backupManifestFileName,
          await manifestFile.length(),
          await manifestFile.readAsBytes(),
        ),
      );

      for (final entry in assetEntries) {
        final file = File(entry.originalPath);

        if (!await file.exists()) continue;

        archive.addFile(
          ArchiveFile(
            entry.archivePath,
            await file.length(),
            await file.readAsBytes(),
          ),
        );
      }

      final zipData = ZipEncoder().encode(archive);

      if (zipData.isEmpty) {
        throw Exception('Backup package is empty.');
      }

      final outFile = File(destinationPath);

      if (!await outFile.parent.exists()) {
        await outFile.parent.create(recursive: true);
      }

      if (await outFile.exists()) {
        await outFile.delete();
      }

      await outFile.writeAsBytes(zipData, flush: true);

      return outFile;
    } finally {
      try {
        await _deleteDirectoryIfExists(workDir);
      } catch (_) {}
    }
  }

  static Future<DatabaseImportSummary> importBackupPackageFromPath(
    String sourcePath,
  ) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Selected backup file could not be found.');
    }

    final extractDir = await _makeUniqueTempDir('invenman_import');

    try {
      final bytes = await sourceFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      await _extractArchiveManually(archive, extractDir.path);

      final manifestFile = File(
        p.join(extractDir.path, _backupManifestFileName),
      );

      if (!await manifestFile.exists()) {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }

      final manifestMap = jsonDecode(
        await manifestFile.readAsString(),
      ) as Map<String, dynamic>;

      final manifest = BackupManifest.fromMap(manifestMap);

      if (manifest.app.trim().toLowerCase() != 'invenman') {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }

      if (manifest.databaseFile.trim().isEmpty) {
        throw Exception('Backup database is missing.');
      }

      final extractedDbFile = File(
        p.join(extractDir.path, manifest.databaseFile),
      );

      if (!await extractedDbFile.exists()) {
        throw Exception('Backup database is missing.');
      }

    final pathRemap = await _restoreBackupAssets(
      extractDir: extractDir,
      manifest: manifest,
    );

    try {
      return await _importDatabaseFromPreparedPath(
        extractedDbFile.path,
        pathRemap: pathRemap,
      );
    } catch (_) {
      await _deleteImportedAssets(pathRemap.values);
      rethrow;
    }  
    } on ArchiveException {
      throw Exception('Selected file is not a valid InvenMan backup.');
    } on FormatException {
      throw Exception('Selected file is not a valid InvenMan backup.');
    } on FileSystemException catch (e) {
      throw Exception('Import failed: ${e.message}');
    } finally {
      try {
        await Future.delayed(const Duration(milliseconds: 120));
        await _deleteDirectoryIfExists(extractDir);
      } catch (_) {}
    }
  }

  static Future<Map<String, String>> _restoreBackupAssets({
    required Directory extractDir,
    required BackupManifest manifest,
  }) async {
    final remap = <String, String>{};

    for (final entry in manifest.assets) {
      final extractedFile = File(
        p.join(extractDir.path, entry.archivePath),
      );

      if (!await extractedFile.exists()) {
        continue;
      }

      final importedPath = await _copyImportedAssetToAppStorage(
        extractedFile,
        kind: entry.kind,
      );

      remap[entry.originalPath] = importedPath;
    }

    return remap;
  }

  static Future<String> _copyImportedAssetToAppStorage(
    File sourceFile, {
    required String kind,
  }) async {
    final baseDir = await getApplicationSupportDirectory();
    final folderName =
        kind == 'installment' ? 'installment_images' : 'product_images';

    final targetDir = Directory(
      p.join(baseDir.path, 'invenman', folderName),
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = p.extension(sourceFile.path).isEmpty
        ? '.jpg'
        : p.extension(sourceFile.path);

    final prefix = kind == 'installment' ? 'installment' : 'product';

    _importAssetSequence = (_importAssetSequence + 1) % 100000;
    final targetPath = p.join(
      targetDir.path,
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_importAssetSequence$ext',
    );

    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  static Future<DatabaseImportSummary> _importDatabaseFromPreparedPath(
    String sourcePath, {
    required Map<String, String> pathRemap,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Prepared import database could not be found.');
    }

    await _assertImportFileLooksValid(sourcePath);

    final tempDir = await _makeUniqueTempDir('invenman_import_db');
    final tempCopyPath = p.join(tempDir.path, 'database.sqlite');
    final tempCopy = await sourceFile.copy(tempCopyPath);

    sqflite.Database? importDb;

    try {
      importDb = await AppDatabase.openDatabaseAtPath(tempCopy.path);

      final targetDb = await AppDatabase.db;

      int itemsInserted = 0;
      int salesInserted = 0;
      int plansInserted = 0;
      int paymentsInserted = 0;
      int historyInserted = 0;

      final itemIdMap = <int, int>{};
      final saleIdMap = <int, int>{};
      final planIdMap = <int, int>{};

      final itemRows = await importDb.query('items', orderBy: 'id ASC');
      final saleRows =
          await importDb.query('sale_records', orderBy: 'id ASC');
      final planRows =
          await importDb.query('installment_plans', orderBy: 'id ASC');
      final paymentRows =
          await importDb.query('installment_payments', orderBy: 'id ASC');
      final historyRows =
          await importDb.query('history_entries', orderBy: 'id ASC');

      await targetDb.transaction((txn) async {
        for (final row in itemRows) {
          final item = Item.fromMap(row);

          final sanitizedItem = item.copyWith(
            imagePaths: _remapImportedPaths(
              item.imagePaths,
              pathRemap,
            ),
          );

          final newId = await txn.insert(
            'items',
            _withoutId(sanitizedItem.toMap()),
          );

          if (item.id != null) {
            itemIdMap[item.id!] = newId;
          }

          itemsInserted++;
        }

        for (final row in saleRows) {
          final sale = SaleRecord.fromMap(row);

          final sanitizedSale = sale.copyWith(
            itemId: sale.itemId == null ? null : itemIdMap[sale.itemId!],
            installmentImagePaths: _remapImportedPaths(
              sale.installmentImagePaths,
              pathRemap,
            ),
          );

          final newId = await txn.insert(
            'sale_records',
            _withoutId(sanitizedSale.toMap()),
          );

          if (sale.id != null) {
            saleIdMap[sale.id!] = newId;
          }

          salesInserted++;
        }

        for (final row in planRows) {
          final plan = InstallmentPlan.fromMap(row);
          final newSaleRecordId = saleIdMap[plan.saleRecordId];

          if (newSaleRecordId == null) {
            continue;
          }

          final sanitizedPlan = plan.copyWith(
            saleRecordId: newSaleRecordId,
            installmentImagePaths: _remapImportedPaths(
              plan.installmentImagePaths,
              pathRemap,
            ),
          );

          final newId = await txn.insert(
            'installment_plans',
            _withoutId(sanitizedPlan.toMap()),
          );

          if (plan.id != null) {
            planIdMap[plan.id!] = newId;
          }

          plansInserted++;
        }

        for (final row in paymentRows) {
          final payment = InstallmentPayment.fromMap(row);
          final newPlanId = planIdMap[payment.installmentPlanId];

          if (newPlanId == null) {
            continue;
          }

          final sanitizedPayment = payment.copyWith(
            installmentPlanId: newPlanId,
          );

          await txn.insert(
            'installment_payments',
            _withoutId(sanitizedPayment.toMap()),
          );

          paymentsInserted++;
        }

        for (final row in historyRows) {
          final history = HistoryEntry.fromMap(row);

          await txn.insert(
            'history_entries',
            _withoutId(history.toMap()),
          );

          historyInserted++;
        }
      });

      return DatabaseImportSummary(
        itemsInserted: itemsInserted,
        salesInserted: salesInserted,
        installmentPlansInserted: plansInserted,
        installmentPaymentsInserted: paymentsInserted,
        historyInserted: historyInserted,
      );
    } on sqflite.DatabaseException {
      throw Exception('Selected file is not a valid InvenMan backup.');
    } finally {
      await importDb?.close();

      try {
        await Future.delayed(const Duration(milliseconds: 120));
        await _deleteDirectoryIfExists(tempDir);
      } catch (_) {}
    }
  }

  static List<String> _remapImportedPaths(
    List<String> originalPaths,
    Map<String, String> pathRemap,
  ) {
    final cleaned = <String>[];
    final seen = <String>{};

    for (final original in originalPaths) {
      final mapped = pathRemap[original];

      if (mapped == null || mapped.trim().isEmpty) continue;
      if (seen.contains(mapped)) continue;

      cleaned.add(mapped);
      seen.add(mapped);
    }

    return cleaned;
  }

  static Future<void> _assertImportFileLooksValid(String sourcePath) async {
    sqflite.Database? validationDb;

    try {
      validationDb = await AppDatabase.platformDatabaseFactory.openDatabase(
        sourcePath,
        options: sqflite.OpenDatabaseOptions(
          readOnly: true,
          singleInstance: false,
        ),
      );

      final tables = await validationDb.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
      ''');

      final tableNames = tables
          .map((row) => row['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      const requiredTables = {
        'items',
        'sale_records',
        'installment_plans',
        'installment_payments',
        'history_entries',
      };

      if (!tableNames.containsAll(requiredTables)) {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }
    } finally {
      await validationDb?.close();
    }
  }

  static Future<void> _deleteImportedAssets(Iterable<String> paths) async {
    for (final path in paths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;

      try {
        final file = File(trimmed);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {

      }
    }
  }

  static Future<void> deleteAllAppData() async {
    await AppDatabase.close();

    final supportDir = await getApplicationSupportDirectory();
    final rootDir = Directory(p.join(supportDir.path, 'invenman'));

    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }

    await AppDatabase.db;
  }
}