import 'dart:io';

import 'package:invenman/app/actions/delete_all_data_action.dart';
import 'package:invenman/app/actions/import_backup_action.dart';
import 'package:invenman/models/backup_models.dart';
import 'package:invenman/services/backup/backup_service.dart';

class BackupAppService {
  const BackupAppService._();

  static Future<File> exportDatabaseToPath(String destinationPath) {
    return BackupService.exportDatabaseToPath(destinationPath);
  }

  static Future<File> exportBackupPackageToPath(String destinationPath) {
    return BackupService.exportBackupPackageToPath(destinationPath);
  }

  static Future<DatabaseImportSummary> importBackupPackageFromPath(
    String sourcePath,
  ) {
    return ImportBackupAction.execute(sourcePath);
  }

  static Future<void> deleteAllAppData() {
    return DeleteAllAppDataAction.execute();
  }
}