import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:archive/archive_io.dart';

import 'package:invenman/models/history.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/image_service.dart';
import 'package:invenman/services/db_migrations.dart';

class InstallmentDocumentSyncResult {
  final int saleRecordId;
  final int? installmentPlanId;
  final List<String> imagePaths;

  const InstallmentDocumentSyncResult({
    required this.saleRecordId,
    required this.installmentPlanId,
    required this.imagePaths,
  });
}

class DatabaseImportSummary {
  final int itemsInserted;
  final int salesInserted;
  final int installmentPlansInserted;
  final int installmentPaymentsInserted;
  final int historyInserted;

  const DatabaseImportSummary({
    required this.itemsInserted,
    required this.salesInserted,
    required this.installmentPlansInserted,
    required this.installmentPaymentsInserted,
    required this.historyInserted,
  });

  int get totalRowsInserted =>
      itemsInserted +
      salesInserted +
      installmentPlansInserted +
      installmentPaymentsInserted +
      historyInserted;
}

class BackupAssetManifestEntry {
  final String originalPath;
  final String archivePath;
  final String kind;

  const BackupAssetManifestEntry({
    required this.originalPath,
    required this.archivePath,
    required this.kind,
  });

  Map<String, dynamic> toMap() => {
        'originalPath': originalPath,
        'archivePath': archivePath,
        'kind': kind,
      };

  factory BackupAssetManifestEntry.fromMap(Map<String, dynamic> map) {
    return BackupAssetManifestEntry(
      originalPath: map['originalPath'] as String? ?? '',
      archivePath: map['archivePath'] as String? ?? '',
      kind: map['kind'] as String? ?? 'product',
    );
  }
}

class BackupManifest {
  final String app;
  final int backupVersion;
  final String createdAt;
  final String databaseFile;
  final int dbSchemaVersion;
  final List<BackupAssetManifestEntry> assets;

  const BackupManifest({
    required this.app,
    required this.backupVersion,
    required this.createdAt,
    required this.databaseFile,
    required this.dbSchemaVersion,
    required this.assets,
  });

  Map<String, dynamic> toMap() => {
        'app': app,
        'backupVersion': backupVersion,
        'createdAt': createdAt,
        'databaseFile': databaseFile,
        'dbSchemaVersion': dbSchemaVersion,
        'assets': assets.map((e) => e.toMap()).toList(),
      };

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    final rawAssets = (map['assets'] as List<dynamic>? ?? const []);
    return BackupManifest(
      app: map['app'] as String? ?? '',
      backupVersion: (map['backupVersion'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] as String? ?? '',
      databaseFile: map['databaseFile'] as String? ?? 'database.sqlite',
      dbSchemaVersion: (map['dbSchemaVersion'] as num?)?.toInt() ?? 1,
      assets: rawAssets
          .whereType<Map>()
          .map((e) => BackupAssetManifestEntry.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class DBHelper {
  static sqflite.Database? _db;
  static bool _isInitialized = false;

  static const String _databaseName = 'inventory.db';
  static const int _databaseVersion = 12;
  static const String _backupManifestFileName = 'manifest.json';
  static const String _backupDatabaseFileName = 'database.sqlite';
  static const int _backupFormatVersion = 1;

  static Future<void> _initPlatform() async {
    if (_isInitialized) return;

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _isInitialized = true;
  }

  static Future<sqflite.Database> get db async {
    await _initPlatform();
    _db ??= await _initDB();
    return _db!;
  }

  static Future<sqflite.Database> _initDB() async {
    final path = await _resolveDatabasePath();

    final factory = (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)
        ? databaseFactory
        : sqflite.databaseFactory;

    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await createDbTables(db);
          await ensureDbIndexes(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await runDbMigrations(
            db,
            oldVersion,
            newVersion,
            nowIsoString: () => _nowUtc().toIso8601String(),
            normalizeExistingInstallmentValues: _normalizeExistingInstallmentValues,
          );
        },
      ),
    );
  }

  static Future<String> _resolveDatabasePath() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(supportDir.path, 'invenman', 'databases'));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final newPath = p.join(dbDir.path, _databaseName);
    final newFile = File(newPath);

    if (await newFile.exists()) {
      return newPath;
    }

    final oldPath = p.join(await sqflite.getDatabasesPath(), _databaseName);
    final oldFile = File(oldPath);

    if (await oldFile.exists()) {
      await oldFile.copy(newPath);
    }

    return newPath;
  }

  static bool get _isDesktopPlatform =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

  static sqflite.DatabaseFactory get _platformDatabaseFactory =>
    _isDesktopPlatform ? databaseFactory : sqflite.databaseFactory;

  static Future<sqflite.Database> _openDatabaseAtPath(String path) async {
    await _initPlatform();

    return _platformDatabaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await createDbTables(db);
          await ensureDbIndexes(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await runDbMigrations(
            db,
            oldVersion,
            newVersion,
            nowIsoString: () => _nowUtc().toIso8601String(),
            normalizeExistingInstallmentValues:
                _normalizeExistingInstallmentValues,
          );
        },
      ),
    );
  }

  static Future<String> getDatabasePath() async {
    await _initPlatform();
    return _resolveDatabasePath();
  }

  static Map<String, dynamic> _withoutId(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.remove('id');
    return copy;
  }

  static Future<void> _deleteDirectoryIfExists(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static AppImageType _inferImageTypeFromPath(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    if (normalized.contains('/installment_images/')) {
      return AppImageType.installment;
    }
    return AppImageType.product;
  }

  static String _assetFolderNameForType(AppImageType type) {
    return type == AppImageType.installment
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

    final base = p.basenameWithoutExtension(originalPath)
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
    final dbClient = await db;
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
      final sourcePath = await getDatabasePath();
      await close();

      try {
        final sourceFile = File(sourcePath);
        await sourceFile.copy(destinationPath);
      } finally {
        await db;
      }

      return outFile;
    }
  }

  static Future<File> exportBackupPackageToPath(String destinationPath) async {
    final tempDir = await getTemporaryDirectory();
    final workDir = Directory(
      p.join(tempDir.path, 'invenman_export_${DateTime.now().millisecondsSinceEpoch}'),
    );

    await workDir.create(recursive: true);

    try {
      final dbSnapshotPath = p.join(workDir.path, _backupDatabaseFileName);
      await exportDatabaseToPath(dbSnapshotPath);

      final assetEntries = await _collectBackupAssetEntries();
      final manifest = BackupManifest(
        app: 'InvenMan',
        backupVersion: _backupFormatVersion,
        createdAt: _nowUtc().toIso8601String(),
        databaseFile: _backupDatabaseFileName,
        dbSchemaVersion: _databaseVersion,
        assets: assetEntries,
      );

      final manifestFile = File(p.join(workDir.path, _backupManifestFileName));
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
      // ignore: unnecessary_null_comparison
      if (zipData == null) {
        throw Exception('Could not build backup package.');
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
      await _deleteDirectoryIfExists(workDir);
    }
  }

  static Future<List<BackupAssetManifestEntry>> _collectBackupAssetEntries() async {
    final dbClient = await db;
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

        final type = _inferImageTypeFromPath(path);
        final archivePath = _buildUniqueArchiveAssetPath(
          folderName: _assetFolderNameForType(type),
          originalPath: path,
          usedArchivePaths: usedArchivePaths,
        );

        entries.add(
          BackupAssetManifestEntry(
            originalPath: path,
            archivePath: archivePath,
            kind: type == AppImageType.installment ? 'installment' : 'product',
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

  static Future<DatabaseImportSummary> importBackupPackageFromPath(
    String sourcePath,
  ) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected backup file could not be found.');
    }

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
      p.join(tempDir.path, 'invenman_import_${DateTime.now().millisecondsSinceEpoch}'),
    );

    await extractDir.create(recursive: true);

    try {
      final bytes = await sourceFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, extractDir.path);

      final manifestFile = File(p.join(extractDir.path, _backupManifestFileName));
      if (!await manifestFile.exists()) {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }

      final manifestMap = jsonDecode(await manifestFile.readAsString())
          as Map<String, dynamic>;
      final manifest = BackupManifest.fromMap(manifestMap);

      if (manifest.app != 'InvenMan') {
        throw Exception('Selected file is not a valid InvenMan backup.');
      }

      final extractedDbFile = File(p.join(extractDir.path, manifest.databaseFile));
      if (!await extractedDbFile.exists()) {
        throw Exception('Backup database is missing.');
      }

      final pathRemap = await _restoreBackupAssets(
        extractDir: extractDir,
        manifest: manifest,
      );

      return await _importDatabaseFromPreparedPath(
        extractedDbFile.path,
        pathRemap: pathRemap,
      );
    } on ArchiveException {
      throw Exception('Selected file is not a valid InvenMan backup.');
    } finally {
      await _deleteDirectoryIfExists(extractDir);
    }
  }

  static Future<Map<String, String>> _restoreBackupAssets({
    required Directory extractDir,
    required BackupManifest manifest,
  }) async {
    final remap = <String, String>{};

    for (final entry in manifest.assets) {
      final extractedFile = File(p.join(extractDir.path, entry.archivePath));
      if (!await extractedFile.exists()) {
        continue;
      }

      final type = entry.kind == 'installment'
          ? AppImageType.installment
          : AppImageType.product;

      final importedPath = await ImageService.importBackupImage(
        sourceFile: extractedFile,
        type: type,
      );

      remap[entry.originalPath] = importedPath;
    }

    return remap;
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

    final tempDir = await getTemporaryDirectory();
    final tempCopyPath = p.join(
      tempDir.path,
      'invenman_import_db_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );

    final tempCopy = await sourceFile.copy(tempCopyPath);

    sqflite.Database? importDb;

    try {
      importDb = await _openDatabaseAtPath(tempCopy.path);
      final targetDb = await db;

      int itemsInserted = 0;
      int salesInserted = 0;
      int plansInserted = 0;
      int paymentsInserted = 0;
      int historyInserted = 0;

      final itemIdMap = <int, int>{};
      final saleIdMap = <int, int>{};
      final planIdMap = <int, int>{};

      final itemRows = await importDb.query('items', orderBy: 'id ASC');
      final saleRows = await importDb.query('sale_records', orderBy: 'id ASC');
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
            imagePaths: _remapImportedPaths(item.imagePaths, pathRemap),
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
      await _deleteFileIfExists(tempCopy);
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
      validationDb = await _platformDatabaseFactory.openDatabase(sourcePath);

      final tables = await validationDb.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
      ''');

      final tableNames = tables
          .map((e) => (e['name'] as String?) ?? '')
          .where((e) => e.isNotEmpty)
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

  static Future<void> deleteAllAppData() async {
    await close();

    final supportDir = await getApplicationSupportDirectory();
    final rootDir = Directory(p.join(supportDir.path, 'invenman'));

    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }

    await db;
  }

  static DateTime _nowUtc() => DateTime.now().toUtc();

  static double _roundMoney(double value) {
    return ((value * 100).round()) / 100.0;
  }

  static double _wholeMoney(double value) {
    if (value <= 0) return 0;
    return value.roundToDouble();
  }

  static DateTime _startOfTodayUtc() {
    final now = _nowUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = (date.year * 12 + date.month - 1) + monthsToAdd;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;

    final lastDayOfTargetMonth = DateTime.utc(newYear, newMonth + 1, 0).day;
    final newDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime.utc(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static List<String> _normalizeSoldColors(List<String> colors) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in colors) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final normalized = _titleCase(trimmed);
      final key = normalized.toLowerCase();

      if (seen.contains(key)) continue;
      seen.add(key);
      cleaned.add(normalized);
    }

    return cleaned;
  }

  static List<double> _buildWholeNumberScheduleAmounts(
    double totalAmount,
    int months,
  ) {
    if (months <= 0) return const [];

    final totalUnits = totalAmount <= 0 ? 0 : totalAmount.round();
    final base = totalUnits ~/ months;
    final remainder = totalUnits % months;

    return List<double>.generate(months, (index) {
      return (base + (index < remainder ? 1 : 0)).toDouble();
    });
  }

  static String _paymentRowStatus({
    required DateTime dueDate,
    required double amountDue,
    required double amountPaid,
  }) {
    const epsilon = 0.009;
    final today = _startOfTodayUtc();

    if (amountPaid >= amountDue - epsilon) return 'paid';
    if (amountPaid > epsilon) return 'partial';
    if (dueDate.isBefore(today)) return 'overdue';
    return 'pending';
  }

  static String _formatWarranties(Map<String, int> warranties) {
    if (warranties.isEmpty) return 'No warranty';

    return warranties.entries
        .map((e) => '${e.key}: ${e.value} month${e.value == 1 ? '' : 's'}')
        .join(', ');
  }

  static String _formatSupplier(String supplier) {
    final trimmed = supplier.trim();
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static String _formatBrand(String brand) {
    final trimmed = brand.trim();
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static List<String> _normalizeColors(List<String> colors) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in colors) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final normalized = _titleCase(trimmed);
      final key = normalized.toLowerCase();

      if (seen.contains(key)) continue;
      seen.add(key);
      cleaned.add(normalized);
    }

    return cleaned;
  }

  static String _formatColors(List<String> colors) {
    final cleaned = _normalizeColors(colors);
    if (cleaned.isEmpty) return 'Not provided';
    return cleaned.join(', ');
  }

  static String _titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _normalizeText(String value) => value.trim();

  static bool _sameText(String a, String b) {
    return _normalizeText(a) == _normalizeText(b);
  }

  static bool _sameMoney(double a, double b) {
    return (_roundMoney(a) - _roundMoney(b)).abs() < 0.009;
  }

  static bool _sameWarranties(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _sameStringLists(List<String> a, List<String> b) {
    final normalizedA = _normalizeColors(a);
    final normalizedB = _normalizeColors(b);

    if (normalizedA.length != normalizedB.length) return false;
    for (int i = 0; i < normalizedA.length; i++) {
      if (normalizedA[i].toLowerCase() != normalizedB[i].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  static String _moneyText(double value) => _roundMoney(value).toStringAsFixed(0);

  static String _arrowChange(String before, String after) => '$before -> $after';

  static void _validateItemFinancials({
    required double costPrice,
    required double sellingPrice,
  }) {
    if (costPrice < 0 || sellingPrice < 0) {
      throw Exception('Cost price and MRP cannot be negative.');
    }
    if (costPrice > sellingPrice) {
      throw Exception('Cost price cannot be greater than MRP.');
    }
  }

  static List<String> _normalizeInstallmentImages(List<String> paths) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in paths) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      if (seen.contains(trimmed)) continue;
      seen.add(trimmed);
      cleaned.add(trimmed);
    }

    if (cleaned.length > 5) {
      return cleaned.take(5).toList();
    }
    return cleaned;
  }

  static String _buildItemSnapshot(Item item) {
    return [
      'Brand: ${_formatBrand(item.brand)}',
      'Colors: ${_formatColors(item.colors)}',
      'Qty: ${item.quantity}',
      'Cost: ${_moneyText(item.costPrice)}',
      'Sell: ${_moneyText(item.sellingPrice)}',
      'Supplier: ${_formatSupplier(item.supplier)}',
      'Warranties: ${_formatWarranties(item.warranties)}',
      'Images: ${item.imagePaths.length}',
    ].join(', ');
  }

  static String _buildItemEditDetails(Item before, Item after) {
    final changes = <String>[];

    if (!_sameText(before.name, after.name)) {
      changes.add('Name: ${_arrowChange(before.name, after.name)}');
    }
    if (!_sameText(before.description, after.description)) {
      final beforeDesc = before.description.trim().isEmpty ? 'Empty' : 'Updated';
      final afterDesc = after.description.trim().isEmpty ? 'Empty' : 'Updated';
      changes.add('Description: ${_arrowChange(beforeDesc, afterDesc)}');
    }
    if (!_sameText(before.category, after.category)) {
      changes.add('Category: ${_arrowChange(before.category, after.category)}');
    }
    if (!_sameText(before.brand, after.brand)) {
      changes.add(
        'Brand: ${_arrowChange(_formatBrand(before.brand), _formatBrand(after.brand))}',
      );
    }
    if (!_sameStringLists(before.colors, after.colors)) {
      changes.add(
        'Colors: ${_arrowChange(_formatColors(before.colors), _formatColors(after.colors))}',
      );
    }
    if (before.quantity != after.quantity) {
      changes.add('Qty: ${_arrowChange('${before.quantity}', '${after.quantity}')}');
    }
    if (!_sameMoney(before.costPrice, after.costPrice)) {
      changes.add(
        'Cost: ${_arrowChange(_moneyText(before.costPrice), _moneyText(after.costPrice))}',
      );
    }
    if (!_sameMoney(before.sellingPrice, after.sellingPrice)) {
      changes.add(
        'Sell: ${_arrowChange(_moneyText(before.sellingPrice), _moneyText(after.sellingPrice))}',
      );
    }
    if (!_sameText(before.supplier, after.supplier)) {
      changes.add(
        'Supplier: ${_arrowChange(_formatSupplier(before.supplier), _formatSupplier(after.supplier))}',
      );
    }
    if (!_sameWarranties(before.warranties, after.warranties)) {
      changes.add(
        'Warranties: ${_arrowChange(_formatWarranties(before.warranties), _formatWarranties(after.warranties))}',
      );
    }
    if (before.imagePaths.length != after.imagePaths.length) {
      changes.add(
        'Images: ${_arrowChange('${before.imagePaths.length}', '${after.imagePaths.length}')}',
      );
    }

    if (changes.isEmpty) {
      return 'No tracked fields changed.';
    }

    return changes.join(', ');
  }

  static Future<void> insertItem(Item item) async {
    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final dbClient = await db;
    final normalizedItem = item.copyWith(
      brand: item.brand.trim(),
      colors: _normalizeColors(item.colors),
    );

    await dbClient.insert('items', normalizedItem.toMap());

    await logHistory(
      normalizedItem.name,
      'Added',
      _buildItemSnapshot(normalizedItem),
    );
  }

  static Future<void> updateItem(Item item) async {
    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final dbClient = await db;

    Item? previousItem;
    if (item.id != null) {
      final maps = await dbClient.query(
        'items',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        previousItem = Item.fromMap(maps.first);
      }
    }

    final normalizedItem = item.copyWith(
      brand: item.brand.trim(),
      colors: _normalizeColors(item.colors),
    );

    await dbClient.update(
      'items',
      normalizedItem.toMap(),
      where: 'id = ?',
      whereArgs: [normalizedItem.id],
    );

    final historyName = previousItem?.name ?? normalizedItem.name;
    final details = previousItem == null
        ? _buildItemSnapshot(normalizedItem)
        : _buildItemEditDetails(previousItem, normalizedItem);

    await logHistory(
      historyName,
      'Edited',
      details,
    );
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await db;

    Item? previousItem;
    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      previousItem = Item.fromMap(maps.first);
    }

    await dbClient.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    await logHistory(
      name,
      'Deleted',
      previousItem == null
          ? 'Item deleted from inventory'
          : _buildItemSnapshot(previousItem),
    );
  }

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) async {
    final dbClient = await db;

    String orderBy = 'name ASC';

    switch (sortBy) {
      case 'cost_price_asc':
        orderBy = 'cost_price ASC';
        break;
      case 'cost_price_desc':
        orderBy = 'cost_price DESC';
        break;
      case 'selling_price_asc':
        orderBy = 'selling_price ASC';
        break;
      case 'selling_price_desc':
        orderBy = 'selling_price DESC';
        break;
      case 'category':
        orderBy = 'category ASC';
        break;
      case 'quantity_asc':
        orderBy = 'quantity ASC';
        break;
      case 'quantity_desc':
        orderBy = 'quantity DESC';
        break;
      case 'updated_at_desc':
        orderBy = 'updated_at DESC';
        break;
      case 'created_at_desc':
        orderBy = 'created_at DESC';
        break;
      default:
        orderBy = 'name ASC';
    }

    final maps = await dbClient.query('items', orderBy: orderBy);
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  static Future<Item?> fetchItemById(int id) async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  static Future<List<String>> fetchDistinctCategories() async {
    final dbClient = await db;

    final result = await dbClient.rawQuery('''
      SELECT DISTINCT category
      FROM items
      WHERE TRIM(category) != ''
      ORDER BY category COLLATE NOCASE ASC
    ''');

    return result
        .map((e) => (e['category'] as String?)?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<void> insertSaleRecord(
    SaleRecord sale, {
    double? downPayment,
  }) async {
    final dbClient = await db;
    final normalizedImages = sale.isInstallment
        ? _normalizeInstallmentImages(sale.installmentImagePaths)
        : const <String>[];
    final normalizedSoldColors = _normalizeSoldColors(sale.soldColors);

    await dbClient.transaction((txn) async {
      final normalizedSale = sale.copyWith(
        soldColors: normalizedSoldColors,
        installmentImagePaths: normalizedImages,
      );

      final saleId = await txn.insert('sale_records', normalizedSale.toMap());

      if (normalizedSale.paymentType == 'installment' &&
          normalizedSale.installmentMonths != null) {
        await _createInstallmentPlanForSaleTxn(
          txn,
          saleRecordId: saleId,
          sale: normalizedSale.copyWith(id: saleId),
          downPayment: downPayment ?? 0,
        );
      }

      final details = StringBuffer()
        ..write('Qty: ${normalizedSale.quantitySold}')
        ..write(', Sell: ${_moneyText(normalizedSale.sellPrice)}')
        ..write(', Profit: ${_moneyText(normalizedSale.profit)}');

      if (normalizedSale.soldColors.isNotEmpty) {
        details.write(', Colors: ${normalizedSale.soldColors.join(', ')}');
      }

      if ((normalizedSale.customerName ?? '').trim().isNotEmpty) {
        details.write(', Customer: ${normalizedSale.customerName}');
      }
      if ((normalizedSale.customerPhone ?? '').trim().isNotEmpty) {
        details.write(', Phone: ${normalizedSale.customerPhone}');
      }

      details.write(', Payment: ${normalizedSale.paymentType}');
      if (normalizedSale.paymentType == 'installment' &&
          normalizedSale.installmentMonths != null) {
        details.write(', Installment: ${normalizedSale.installmentMonths} month(s)');
        details.write(', Down Payment: ${_moneyText(downPayment ?? 0)}');
        details.write(', Files: ${normalizedImages.length}');
      }

      details.write(', Warranties: ${_formatWarranties(normalizedSale.warranties)}');

      await txn.insert('history_entries', {
        'item_name': normalizedSale.itemName,
        'action': 'Sold',
        'details': details.toString(),
        'created_at': _nowUtc().toIso8601String(),
      });
    });
  }

  static Future<List<SaleRecord>> fetchSaleRecords() async {
    final dbClient = await db;
    final maps = await dbClient.query('sale_records', orderBy: 'sold_at DESC');
    return maps.map((map) => SaleRecord.fromMap(map)).toList();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SaleRecord.fromMap(maps.first);
  }

  static Future<void> logHistory(
    String itemName,
    String action,
    String details,
  ) async {
    final dbClient = await db;
    await dbClient.insert('history_entries', {
      'item_name': itemName,
      'action': action,
      'details': details,
      'created_at': _nowUtc().toIso8601String(),
    });
  }

  static Future<List<HistoryEntry>> fetchHistoryEntries() async {
    final dbClient = await db;
    final maps = await dbClient.query('history_entries', orderBy: 'created_at DESC');
    return maps.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  static Future<void> sellItem({
    required Item item,
    required int quantitySold,
    required double sellPricePerUnit,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    required String paymentType,
    int? installmentMonths,
    double? downPayment,
    List<String> soldColors = const [],
    List<String> installmentImagePaths = const [],
  }) async {
    final dbClient = await db;

    if (item.id == null) {
      throw Exception('Cannot sell an item without an id.');
    }

    if (quantitySold <= 0) {
      throw Exception('Quantity sold must be greater than zero.');
    }

    if (item.quantity < quantitySold) {
      throw Exception('Not enough stock available.');
    }

    if (paymentType != 'direct' && paymentType != 'installment') {
      throw Exception('Payment type must be either direct or installment.');
    }

    final totalSaleAmount = _roundMoney(sellPricePerUnit * quantitySold);

    if (paymentType == 'installment' &&
        (installmentMonths == null || installmentMonths <= 0)) {
      throw Exception('Installment duration must be greater than zero.');
    }

    final normalizedInstallmentImages = paymentType == 'installment'
        ? _normalizeInstallmentImages(installmentImagePaths)
        : const <String>[];

    final normalizedSoldColors = _normalizeSoldColors(soldColors);

    if (item.colors.isNotEmpty && normalizedSoldColors.isEmpty) {
      throw Exception('Please select at least one sold color.');
    }

    if (paymentType == 'installment') {
      if (downPayment == null) {
        throw Exception('Down payment is required for installment sales.');
      }
      if (downPayment < 0) {
        throw Exception('Down payment cannot be negative.');
      }
      if (downPayment <= 0) {
        throw Exception('Down payment must be greater than zero.');
      }
      if (downPayment >= totalSaleAmount) {
        throw Exception('Down payment must be less than total sale amount.');
      }
    }

    if (paymentType == 'direct') {
      installmentMonths = null;
      downPayment = null;
    }

    final now = _nowUtc();

    final updatedItem = item.copyWith(
      quantity: item.quantity - quantitySold,
      updatedAt: now,
    );

    final profit = (sellPricePerUnit - item.costPrice) * quantitySold;

    final sale = SaleRecord(
      itemId: item.id!,
      itemName: item.name,
      category: item.category,
      quantitySold: quantitySold,
      costPrice: item.costPrice,
      sellPrice: sellPricePerUnit,
      profit: profit,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentType: paymentType,
      installmentMonths: installmentMonths,
      soldColors: normalizedSoldColors,
      installmentImagePaths: normalizedInstallmentImages,
      warranties: item.warranties,
      soldAt: now,
    );

    await dbClient.transaction((txn) async {
      await txn.update(
        'items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      final saleId = await txn.insert('sale_records', sale.toMap());

      if (paymentType == 'installment' && installmentMonths != null) {
        await _createInstallmentPlanForSaleTxn(
          txn,
          saleRecordId: saleId,
          sale: sale.copyWith(id: saleId),
          downPayment: downPayment ?? 0,
        );
      }

      final details = StringBuffer()
        ..write('Qty: $quantitySold')
        ..write(', Sell: ${_moneyText(sellPricePerUnit)}')
        ..write(', Profit: ${_moneyText(profit)}')
        ..write(', Stock: ${item.quantity} -> ${updatedItem.quantity}');

      if (normalizedSoldColors.isNotEmpty) {
        details.write(', Colors: ${normalizedSoldColors.join(', ')}');
      }

      if ((customerName ?? '').trim().isNotEmpty) {
        details.write(', Customer: $customerName');
      }
      if ((customerPhone ?? '').trim().isNotEmpty) {
        details.write(', Phone: $customerPhone');
      }

      details.write(', Payment: $paymentType');
      if (paymentType == 'installment' && installmentMonths != null) {
        details.write(', Installment: $installmentMonths month(s)');
        details.write(', Down Payment: ${_moneyText(downPayment ?? 0)}');
        details.write(', Files: ${normalizedInstallmentImages.length}');
      }

      details.write(', Warranties: ${_formatWarranties(item.warranties)}');

      await txn.insert('history_entries', {
        'item_name': item.name,
        'action': 'Sold',
        'details': details.toString(),
        'created_at': now.toIso8601String(),
      });
    });
  }

  static Future<int> _createInstallmentPlanForSaleTxn(
    sqflite.Transaction txn, {
    required int saleRecordId,
    required SaleRecord sale,
    required double downPayment,
  }) async {
    if (sale.installmentMonths == null || sale.installmentMonths! <= 0) {
      throw Exception('Installment duration is required for installment plans.');
    }

    final now = _nowUtc();
    final totalAmount = _roundMoney(sale.sellPrice * sale.quantitySold);
    final normalizedDownPayment = _roundMoney(downPayment);

    if (normalizedDownPayment <= 0) {
      throw Exception('Down payment must be greater than zero.');
    }
    if (normalizedDownPayment >= totalAmount) {
      throw Exception('Down payment must be less than total sale amount.');
    }

    final financedAmount = _roundMoney(totalAmount - normalizedDownPayment);
    final durationMonths = sale.installmentMonths!;
    final scheduleAmounts =
        _buildWholeNumberScheduleAmounts(financedAmount, durationMonths);
    final monthlyAmount =
        scheduleAmounts.isNotEmpty ? scheduleAmounts.first : 0.0;
    final nextDueDate = _addMonths(sale.soldAt, 1);
    final normalizedImages = _normalizeInstallmentImages(sale.installmentImagePaths);

    final planId = await txn.insert('installment_plans', {
      'sale_record_id': saleRecordId,
      'item_name': sale.itemName,
      'category': sale.category,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'customer_address': sale.customerAddress,
      'image_paths_json': jsonEncode(normalizedImages),
      'total_amount': totalAmount,
      'down_payment': normalizedDownPayment,
      'financed_amount': financedAmount,
      'duration_months': durationMonths,
      'monthly_amount': monthlyAmount,
      'start_date': sale.soldAt.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'paid_months': 0,
      'remaining_months': durationMonths,
      'total_paid': normalizedDownPayment,
      'remaining_balance': financedAmount,
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    for (int i = 0; i < durationMonths; i++) {
      final dueDate = _addMonths(sale.soldAt, i + 1);
      final amountDue = scheduleAmounts[i];
      final status = _paymentRowStatus(
        dueDate: dueDate,
        amountDue: amountDue,
        amountPaid: 0,
      );

      await txn.insert('installment_payments', {
        'installment_plan_id': planId,
        'installment_number': i + 1,
        'due_date': dueDate.toIso8601String(),
        'paid_date': null,
        'amount_due': amountDue,
        'amount_paid': 0.0,
        'status': status,
        'note': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }

    await txn.insert('history_entries', {
      'item_name': sale.itemName,
      'action': 'Installment',
      'details':
          'Plan created: ${durationMonths} month(s), Total: ${_moneyText(totalAmount)}, Down Payment: ${_moneyText(normalizedDownPayment)}, Financed: ${_moneyText(financedAmount)}, Monthly approx: ${_moneyText(monthlyAmount)}, Installment Files: ${normalizedImages.length}',
      'created_at': now.toIso8601String(),
    });

    await _recalculateInstallmentPlanTxn(txn, planId);
    return planId;
  }

  static Future<void> _redistributeFuturePaymentsTxn(
    sqflite.Transaction txn,
    InstallmentPlan plan,
    int anchorInstallmentNumber,
  ) async {
    final paymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [plan.id],
      orderBy: 'installment_number ASC',
    );

    if (paymentMaps.isEmpty) return;

    final payments = paymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    double totalPaidTowardInstallments = 0.0;
    for (final payment in payments) {
      totalPaidTowardInstallments += payment.amountPaid;
    }
    totalPaidTowardInstallments = _roundMoney(totalPaidTowardInstallments);

    double financedRemaining = _roundMoney(plan.financedAmount - totalPaidTowardInstallments);
    if (financedRemaining < 0) financedRemaining = 0;

    double lockedOutstanding = 0.0;
    final redistributable = <InstallmentPayment>[];

    for (final payment in payments) {
      final normalizedDue = payment.amountPaid > payment.amountDue
          ? payment.amountPaid
          : payment.amountDue;

      final computedStatus = _paymentRowStatus(
        dueDate: payment.dueDate,
        amountDue: normalizedDue,
        amountPaid: payment.amountPaid,
      );

      final isLocked =
          payment.installmentNumber <= anchorInstallmentNumber ||
          computedStatus == 'paid';

      if (isLocked) {
        final outstanding = normalizedDue - payment.amountPaid;
        if (outstanding > 0) {
          lockedOutstanding += outstanding;
        }

        if ((normalizedDue - payment.amountDue).abs() > 0.009) {
          await txn.update(
            'installment_payments',
            {
              'amount_due': _wholeMoney(normalizedDue),
              'updated_at': _nowUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      } else {
        redistributable.add(payment);
      }
    }

    lockedOutstanding = _roundMoney(lockedOutstanding);

    double outstandingToAllocate = _roundMoney(financedRemaining - lockedOutstanding);
    if (outstandingToAllocate < 0) {
      outstandingToAllocate = 0;
    }

    final redistributedOutstanding = _buildWholeNumberScheduleAmounts(
      outstandingToAllocate,
      redistributable.length,
    );

    for (int i = 0; i < redistributable.length; i++) {
      final payment = redistributable[i];
      final newAmountDue = _wholeMoney(payment.amountPaid + redistributedOutstanding[i]);

      await txn.update(
        'installment_payments',
        {
          'amount_due': newAmountDue,
          'updated_at': _nowUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    }
  }

  static Future<void> _recalculateInstallmentPlanTxn(
    sqflite.Transaction txn,
    int planId, {
    int? anchorInstallmentNumber,
  }) async {
    final planMaps = await txn.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );

    if (planMaps.isEmpty) return;

    final plan = InstallmentPlan.fromMap(planMaps.first);

    if (anchorInstallmentNumber != null) {
      await _redistributeFuturePaymentsTxn(
        txn,
        plan,
        anchorInstallmentNumber,
      );
    }

    final refreshedPaymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [planId],
      orderBy: 'installment_number ASC',
    );

    if (refreshedPaymentMaps.isEmpty) return;

    final payments =
        refreshedPaymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    final now = _nowUtc();

    double paymentRowsTotalPaid = 0.0;
    for (final payment in payments) {
      paymentRowsTotalPaid += payment.amountPaid;
    }
    paymentRowsTotalPaid = _roundMoney(paymentRowsTotalPaid);

    final totalPaid = _roundMoney(plan.downPayment + paymentRowsTotalPaid);

    double remainingBalance = _roundMoney(plan.totalAmount - totalPaid);
    if (remainingBalance < 0) remainingBalance = 0;

    if (remainingBalance <= 0.009) {
      for (final payment in payments) {
        await txn.update(
          'installment_payments',
          {
            'amount_due': payment.amountPaid > 0
                ? _wholeMoney(payment.amountPaid)
                : 0.0,
            'status': 'paid',
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [payment.id],
        );
      }
    } else {
      for (final payment in payments) {
        final normalizedDue = _wholeMoney(
          payment.amountPaid > payment.amountDue ? payment.amountPaid : payment.amountDue,
        );

        final computedStatus = _paymentRowStatus(
          dueDate: payment.dueDate,
          amountDue: normalizedDue,
          amountPaid: payment.amountPaid,
        );

        final shouldUpdateDue = (normalizedDue - payment.amountDue).abs() > 0.009;
        final shouldUpdateStatus = computedStatus != payment.status;

        if (shouldUpdateDue || shouldUpdateStatus) {
          await txn.update(
            'installment_payments',
            {
              'amount_due': normalizedDue,
              'status': computedStatus,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      }
    }

    final finalPaymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [planId],
      orderBy: 'installment_number ASC',
    );

    final finalPayments =
        finalPaymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    int paidMonths = 0;
    int remainingMonths = 0;
    DateTime? nextDueDate;
    bool hasOverdue = false;
    double nextMonthlyAmount = 0.0;

    for (final payment in finalPayments) {
      if (payment.status == 'paid') {
        paidMonths++;
      } else {
        remainingMonths++;
        nextDueDate ??= payment.dueDate;
        nextMonthlyAmount = payment.amountDue;
      }

      if (payment.status == 'overdue') {
        hasOverdue = true;
      }
    }

    String planStatus;
    if (remainingBalance <= 0.009) {
      planStatus = 'completed';
      nextDueDate = null;
      remainingMonths = 0;
      paidMonths = plan.durationMonths;
      nextMonthlyAmount = 0.0;
    } else if (hasOverdue) {
      planStatus = 'overdue';
    } else {
      planStatus = 'active';
    }

    await txn.update(
      'installment_plans',
      {
        'paid_months': paidMonths,
        'remaining_months': remainingMonths,
        'total_paid': totalPaid,
        'remaining_balance': remainingBalance,
        'next_due_date': nextDueDate?.toIso8601String(),
        'monthly_amount': _wholeMoney(nextMonthlyAmount),
        'status': planStatus,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  static Future<void> _refreshInstallmentStatuses() async {
    final dbClient = await db;
    final planIds = await dbClient.query(
      'installment_plans',
      columns: ['id'],
    );

    if (planIds.isEmpty) return;

    await dbClient.transaction((txn) async {
      for (final row in planIds) {
        final id = row['id'] as int?;
        if (id != null) {
          await _recalculateInstallmentPlanTxn(txn, id);
        }
      }
    });
  }

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    String orderBy;
    switch (sortBy) {
      case 'next_due_desc':
        orderBy = 'next_due_date DESC, updated_at DESC';
        break;
      case 'customer':
        orderBy = 'customer_name COLLATE NOCASE ASC, updated_at DESC';
        break;
      case 'item':
        orderBy = 'item_name COLLATE NOCASE ASC, updated_at DESC';
        break;
      case 'status':
        orderBy = 'status ASC, next_due_date ASC';
        break;
      case 'latest':
        orderBy = 'created_at DESC';
        break;
      case 'next_due_asc':
      default:
        orderBy = 'next_due_date ASC, updated_at DESC';
        break;
    }

    final maps = await dbClient.query(
      'installment_plans',
      orderBy: orderBy,
    );

    return maps.map((map) => InstallmentPlan.fromMap(map)).toList();
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return InstallmentPlan.fromMap(maps.first);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(
    int saleRecordId,
  ) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_plans',
      where: 'sale_record_id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return InstallmentPlan.fromMap(maps.first);
  }

  static Future<List<InstallmentPayment>> fetchInstallmentPayments(
    int installmentPlanId,
  ) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [installmentPlanId],
      orderBy: 'installment_number ASC',
    );

    return maps.map((map) => InstallmentPayment.fromMap(map)).toList();
  }

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) async {
    final dbClient = await db;

    if (amountPaid < 0) {
      throw Exception('Amount paid cannot be negative.');
    }

    await dbClient.transaction((txn) async {
      final paymentMaps = await txn.query(
        'installment_payments',
        where: 'id = ?',
        whereArgs: [installmentPaymentId],
        limit: 1,
      );

      if (paymentMaps.isEmpty) {
        throw Exception('Installment payment entry not found.');
      }

      final payment = InstallmentPayment.fromMap(paymentMaps.first);

      final normalizedPaidDate = amountPaid > 0 ? (paidDate ?? _nowUtc()) : null;
      final normalizedNote = (note ?? '').trim().isEmpty ? null : note?.trim();
      final normalizedAmountDue = amountPaid > payment.amountDue
          ? _wholeMoney(amountPaid)
          : _wholeMoney(payment.amountDue);

      final newStatus = _paymentRowStatus(
        dueDate: payment.dueDate,
        amountDue: normalizedAmountDue,
        amountPaid: amountPaid,
      );

      await txn.update(
        'installment_payments',
        {
          'amount_due': normalizedAmountDue,
          'amount_paid': _roundMoney(amountPaid),
          'paid_date': normalizedPaidDate?.toIso8601String(),
          'status': newStatus,
          'note': normalizedNote,
          'updated_at': _nowUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentPaymentId],
      );

      await _recalculateInstallmentPlanTxn(
        txn,
        payment.installmentPlanId,
        anchorInstallmentNumber: payment.installmentNumber,
      );

      final planMaps = await txn.query(
        'installment_plans',
        where: 'id = ?',
        whereArgs: [payment.installmentPlanId],
        limit: 1,
      );

      if (planMaps.isNotEmpty) {
        final plan = InstallmentPlan.fromMap(planMaps.first);
        final details = StringBuffer()
          ..write('Month ${payment.installmentNumber}')
          ..write(', Paid: ${_moneyText(amountPaid)}');

        if (normalizedPaidDate != null) {
          details.write(', Date: ${normalizedPaidDate.toIso8601String()}');
        }
        if (normalizedNote != null) {
          details.write(', Note: $normalizedNote');
        }

        await txn.insert('history_entries', {
          'item_name': plan.itemName,
          'action': 'Installment Payment',
          'details': details.toString(),
          'created_at': _nowUtc().toIso8601String(),
        });
      }
    });
  }

  static Future<InstallmentDocumentSyncResult> _syncInstallmentDocumentsTxn(
    sqflite.Transaction txn, {
    required int saleRecordId,
    required List<String> imagePaths,
  }) async {
    final nowIso = _nowUtc().toIso8601String();
    final normalizedImages = _normalizeInstallmentImages(imagePaths);
    final encodedImages = jsonEncode(normalizedImages);

    final saleMaps = await txn.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (saleMaps.isEmpty) {
      throw Exception('Sale record not found.');
    }

    final sale = SaleRecord.fromMap(saleMaps.first);

    if (!sale.isInstallment) {
      throw Exception('Only installment sales can have installment documents.');
    }

    await txn.update(
      'sale_records',
      {
        'installment_image_paths_json': encodedImages,
      },
      where: 'id = ?',
      whereArgs: [saleRecordId],
    );

    final planMaps = await txn.query(
      'installment_plans',
      columns: ['id'],
      where: 'sale_record_id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    int? installmentPlanId;
    if (planMaps.isNotEmpty) {
      installmentPlanId = planMaps.first['id'] as int?;
      if (installmentPlanId != null) {
        await txn.update(
          'installment_plans',
          {
            'image_paths_json': encodedImages,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [installmentPlanId],
        );
      }
    }

    await txn.insert('history_entries', {
      'item_name': sale.itemName,
      'action': 'Installment Documents Updated',
      'details':
          'Installment Documents Updated. Count: ${normalizedImages.length}',
      'created_at': nowIso,
    });

    return InstallmentDocumentSyncResult(
      saleRecordId: saleRecordId,
      installmentPlanId: installmentPlanId,
      imagePaths: normalizedImages,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsBySaleRecordId({
    required int saleRecordId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await db;

    return dbClient.transaction((txn) async {
      return _syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsByInstallmentPlanId({
    required int installmentPlanId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await db;

    return dbClient.transaction((txn) async {
      final planMaps = await txn.query(
        'installment_plans',
        columns: ['sale_record_id'],
        where: 'id = ?',
        whereArgs: [installmentPlanId],
        limit: 1,
      );

      if (planMaps.isEmpty) {
        throw Exception('Installment plan not found.');
      }

      final saleRecordId = planMaps.first['sale_record_id'] as int?;
      if (saleRecordId == null) {
        throw Exception('Linked sale record not found.');
      }

      return _syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentBySaleRecordId({
    required int saleRecordId,
    required String imagePath,
  }) async {
    final sale = await fetchSaleRecordById(saleRecordId);
    if (sale == null) {
      throw Exception('Sale record not found.');
    }

    final updatedPaths = List<String>.from(sale.installmentImagePaths)
      ..removeWhere((e) => e == imagePath);

    return updateInstallmentDocumentsBySaleRecordId(
      saleRecordId: saleRecordId,
      imagePaths: updatedPaths,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentByInstallmentPlanId({
    required int installmentPlanId,
    required String imagePath,
  }) async {
    final plan = await fetchInstallmentPlanById(installmentPlanId);
    if (plan == null) {
      throw Exception('Installment plan not found.');
    }

    final updatedPaths = List<String>.from(plan.installmentImagePaths)
      ..removeWhere((e) => e == imagePath);

    return updateInstallmentDocumentsByInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePaths: updatedPaths,
    );
  }

  static Future<void> _normalizeExistingInstallmentValues(
    sqflite.DatabaseExecutor db,
  ) async {
    final planMaps = await db.query(
      'installment_plans',
      columns: ['id'],
    );

    if (planMaps.isEmpty) return;

    for (final row in planMaps) {
      final id = row['id'] as int?;
      if (id == null) continue;

      final paymentMaps = await db.query(
        'installment_payments',
        where: 'installment_plan_id = ?',
        whereArgs: [id],
        orderBy: 'installment_number ASC',
      );

      for (final paymentMap in paymentMaps) {
        final payment = InstallmentPayment.fromMap(paymentMap);
        final normalizedDue = _wholeMoney(
          payment.amountPaid > payment.amountDue ? payment.amountPaid : payment.amountDue,
        );
        final normalizedPaid = _roundMoney(payment.amountPaid);

        if ((normalizedDue - payment.amountDue).abs() > 0.009 ||
            (normalizedPaid - payment.amountPaid).abs() > 0.009) {
          await db.update(
            'installment_payments',
            {
              'amount_due': normalizedDue,
              'amount_paid': normalizedPaid,
              'updated_at': _nowUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      }

      if (db is sqflite.Transaction) {
        await _recalculateInstallmentPlanTxn(db, id);
      }
    }
  }

  static Future<void> clearAllData() async {
    await deleteAllAppData();
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}