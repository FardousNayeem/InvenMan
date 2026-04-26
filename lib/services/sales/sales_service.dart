import 'package:invenman/app/actions/sell_item_action.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/repositories/sale_repository.dart';

class SalesService {
  const SalesService._();

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  static Future<List<SaleRecord>> fetchSaleRecords() {
    return SaleRepository.fetchSaleRecords();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) {
    return SaleRepository.fetchSaleRecordById(id);
  }

  // ---------------------------------------------------------------------------
  // Workflows
  //
  // Sale creation must stay behind SellItemAction because it updates inventory,
  // writes sale history, and may create installment records transactionally.
  // ---------------------------------------------------------------------------

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
  }) {
    return SellItemAction.execute(
      item: item,
      quantitySold: quantitySold,
      sellPricePerUnit: sellPricePerUnit,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentType: paymentType,
      installmentMonths: installmentMonths,
      downPayment: downPayment,
      soldColors: soldColors,
      installmentImagePaths: installmentImagePaths,
    );
  }
}