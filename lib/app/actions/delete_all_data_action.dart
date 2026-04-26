import 'package:invenman/services/backup/backup_service.dart';

class DeleteAllAppDataAction {
  const DeleteAllAppDataAction._();

  static Future<void> execute() {
    return BackupService.deleteAllAppData();
  }
}