import 'package:invenman/models/backup_models.dart';
import 'package:invenman/services/backup/backup_service.dart';

class ImportBackupAction {
  const ImportBackupAction._();

  static Future<DatabaseImportSummary> execute(String sourcePath) {
    return BackupService.importBackupPackageFromPath(sourcePath);
  }
}