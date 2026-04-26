import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class SaleRepository {
  const SaleRepository._();

  static DateTime _nowUtc() => DbShared.nowUtc();

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
    final dbClient = await AppDatabase.db;

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

      final saleId = await txn.insert(
        'sale_records',
        sale.toMap(),
      );

      if (paymentType == 'installment' && installmentMonths != null) {
        await InstallmentRepository.createInstallmentPlanForSaleTxn(
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
        details.write(', Docs: ${normalizedInstallmentImages.length}');
      }

      details.write(', Warranties: ${_formatWarranties(item.warranties)}');

      await HistoryRepository.logHistory(
        itemName: item.name,
        action: 'Sold',
        details: details.toString(),
        executor: txn,
      );
    });
  }
}