import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class SaleRepository {
  const SaleRepository._();

  static double _roundMoney(double value) => DbShared.roundMoney(value);

  static String _moneyText(double value) {
    return _roundMoney(value).toStringAsFixed(0);
  }

  static String _titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
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

  static List<String> _normalizeInstallmentImages(List<String> paths) {
    return InstallmentRepository.normalizeInstallmentImages(paths);
  }

  static String _formatWarranties(Map<String, int> warranties) {
    if (warranties.isEmpty) return 'No warranty';

    return warranties.entries
        .map((entry) {
          final suffix = entry.value == 1 ? '' : 's';
          return '${entry.key}: ${entry.value} month$suffix';
        })
        .join(', ');
  }

  static Future<void> insertSaleRecord(
    SaleRecord sale, {
    double? downPayment,
  }) async {
    final dbClient = await AppDatabase.db;

    final normalizedImages = sale.isInstallment
        ? _normalizeInstallmentImages(sale.installmentImagePaths)
        : const <String>[];

    final normalizedSoldColors = _normalizeSoldColors(sale.soldColors);

    await dbClient.transaction((txn) async {
      final normalizedSale = sale.copyWith(
        soldColors: normalizedSoldColors,
        installmentImagePaths: normalizedImages,
      );

      final saleId = await txn.insert(
        'sale_records',
        normalizedSale.toMap(),
      );

      if (normalizedSale.paymentType == 'installment' &&
          normalizedSale.installmentMonths != null) {
        await InstallmentRepository.createInstallmentPlanForSaleTxn(
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
        details.write(
          ', Installment: ${normalizedSale.installmentMonths} month(s)',
        );
        details.write(', Down Payment: ${_moneyText(downPayment ?? 0)}');
        details.write(', Docs: ${normalizedImages.length}');
      }

      details.write(
        ', Warranties: ${_formatWarranties(normalizedSale.warranties)}',
      );

      await HistoryRepository.logHistory(
        itemName: normalizedSale.itemName,
        action: 'Sold',
        details: details.toString(),
        executor: txn,
      );
    });
  }

  static Future<List<SaleRecord>> fetchSaleRecords() async {
    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'sale_records',
      orderBy: 'sold_at DESC',
    );

    return maps.map(SaleRecord.fromMap).toList();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) async {
    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return SaleRecord.fromMap(maps.first);
  }
}