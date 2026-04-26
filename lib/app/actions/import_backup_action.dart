import 'package:invenman/services/backup/backup_models.dart';
import 'package:invenman/services/backup/backup_service.dart';

class ImportBackupAction {
  const ImportBackupAction._();

  static Future<DatabaseImportSummary> execute(String sourcePath) {
    return BackupService.importBackupPackageFromPath(sourcePath);
  }

  static Future<DatabaseImportSummary> executeDatabaseImport(
    String sourcePath,
  ) {
    return BackupService.importDatabaseFromPath(sourcePath);
  }
}