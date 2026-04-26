import 'package:invenman/models/history.dart';
import 'package:invenman/services/repositories/history_repository.dart';

class HistoryService {
  const HistoryService._();

  static Future<List<HistoryEntry>> fetchEntries() {
    return HistoryRepository.fetchHistoryEntries();
  }
}