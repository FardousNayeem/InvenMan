import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class DBHelper {
  const DBHelper._();

  static bool _registeredDatabaseCallbacks = false;

  static void _ensureDatabaseCallbacksRegistered() {
    if (_registeredDatabaseCallbacks) return;

    AppDatabase.registerNormalizeExistingInstallmentValues(
      InstallmentRepository.normalizeExistingInstallmentValues,
    );

    _registeredDatabaseCallbacks = true;
  }

  static Future<void> initialize() async {
    _ensureDatabaseCallbacksRegistered();
    await AppDatabase.db;
  }

  static Future<String> getDatabasePath() {
    _ensureDatabaseCallbacksRegistered();
    return AppDatabase.getDatabasePath();
  }

  static Future<void> close() {
    return AppDatabase.close();
  }
}