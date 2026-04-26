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

  int get totalRowsInserted {
    return itemsInserted +
        salesInserted +
        installmentPlansInserted +
        installmentPaymentsInserted +
        historyInserted;
  }
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

  Map<String, dynamic> toMap() {
    return {
      'originalPath': originalPath,
      'archivePath': archivePath,
      'kind': kind,
    };
  }

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

  Map<String, dynamic> toMap() {
    return {
      'app': app,
      'backupVersion': backupVersion,
      'createdAt': createdAt,
      'databaseFile': databaseFile,
      'dbSchemaVersion': dbSchemaVersion,
      'assets': assets.map((entry) => entry.toMap()).toList(),
    };
  }

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    final rawAssets = map['assets'] as List<dynamic>? ?? const [];

    return BackupManifest(
      app: map['app'] as String? ?? '',
      backupVersion: (map['backupVersion'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] as String? ?? '',
      databaseFile: map['databaseFile'] as String? ?? 'database.sqlite',
      dbSchemaVersion: (map['dbSchemaVersion'] as num?)?.toInt() ?? 1,
      assets: rawAssets
          .whereType<Map>()
          .map(
            (entry) => BackupAssetManifestEntry.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(),
    );
  }
}