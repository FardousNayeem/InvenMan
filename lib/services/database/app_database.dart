import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/database/db_migrations.dart';

class AppDatabase {
  const AppDatabase._();

  static sqflite.Database? _db;
  static bool _isInitialized = false;

  static const String databaseName = 'inventory.db';
  static const int databaseVersion = 13;

  static NormalizeExistingInstallmentValues?
      _normalizeExistingInstallmentValues;

  static void registerNormalizeExistingInstallmentValues(
    NormalizeExistingInstallmentValues callback,
  ) {
    _normalizeExistingInstallmentValues = callback;
  }

  static bool get isDesktopPlatform {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static sqflite.DatabaseFactory get platformDatabaseFactory {
    return isDesktopPlatform ? databaseFactory : sqflite.databaseFactory;
  }

  static Future<void> initPlatform() async {
    if (_isInitialized) return;

    if (isDesktopPlatform) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _isInitialized = true;
  }

  static Future<sqflite.Database> get db async {
    await initPlatform();
    _db ??= await _initDB();
    return _db!;
  }

  static Future<sqflite.Database> _initDB() async {
    final path = await resolveDatabasePath();
    return openDatabaseAtPath(path);
  }

  static Future<String> resolveDatabasePath() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(join(supportDir.path, 'invenman', 'databases'));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final newPath = join(dbDir.path, databaseName);
    final newFile = File(newPath);

    if (await newFile.exists()) {
      return newPath;
    }

    final oldPath = join(await sqflite.getDatabasesPath(), databaseName);
    final oldFile = File(oldPath);

    if (await oldFile.exists()) {
      await oldFile.copy(newPath);
    }

    return newPath;
  }

  static Future<String> getDatabasePath() async {
    await initPlatform();
    return resolveDatabasePath();
  }

  static Future<sqflite.Database> openDatabaseAtPath(String path) async {
    await initPlatform();

    return platformDatabaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: databaseVersion,
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
            nowIsoString: () => DbShared.nowUtc().toIso8601String(),
            normalizeExistingInstallmentValues:
                _normalizeExistingInstallmentValues ?? _noopNormalize,
          );
        },
      ),
    );
  }

  static Future<void> _noopNormalize(sqflite.DatabaseExecutor db) async {}

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}