import 'package:invenman/app/core/app_exception.dart';

import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/sale_record.dart';

import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class UpdateInstallmentDocumentsAction {
  const UpdateInstallmentDocumentsAction._();

  static Future<InstallmentDocumentSyncResult> bySaleRecordId({
    required int saleRecordId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await AppDatabase.db;

    return dbClient.transaction((txn) async {
      return InstallmentRepository.syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult> byInstallmentPlanId({
    required int installmentPlanId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await AppDatabase.db;

    return dbClient.transaction((txn) async {
      final planMaps = await txn.query(
        'installment_plans',
        columns: ['sale_record_id'],
        where: 'id = ?',
        whereArgs: [installmentPlanId],
        limit: 1,
      );

      if (planMaps.isEmpty) {
        throw const AppException.notFound(
          code: 'installment_plan_not_found',
          message: 'Installment plan not found.',
        );
      }

      final saleRecordId = planMaps.first['sale_record_id'] as int?;

      if (saleRecordId == null) {
        throw const AppException.notFound(
          code: 'installment_plan_missing_sale_record',
          message: 'Linked sale record not found.',
        );
      }

      return InstallmentRepository.syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult> removeBySaleRecordId({
    required int saleRecordId,
    required String imagePath,
  }) async {
    final dbClient = await AppDatabase.db;

    final saleMaps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (saleMaps.isEmpty) {
      throw const AppException.notFound(
        code: 'sale_record_not_found',
        message: 'Sale record not found.',
      );
    }

    final sale = SaleRecord.fromMap(saleMaps.first);

    final updatedPaths = List<String>.from(sale.installmentImagePaths)
      ..removeWhere((path) => path == imagePath);

    return bySaleRecordId(
      saleRecordId: saleRecordId,
      imagePaths: updatedPaths,
    );
  }

  static Future<InstallmentDocumentSyncResult> removeByInstallmentPlanId({
    required int installmentPlanId,
    required String imagePath,
  }) async {
    final dbClient = await AppDatabase.db;

    final planMaps = await dbClient.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [installmentPlanId],
      limit: 1,
    );

    if (planMaps.isEmpty) {
      throw const AppException.notFound(
        code: 'installment_plan_not_found',
        message: 'Installment plan not found.',
      );
    }

    final plan = InstallmentPlan.fromMap(planMaps.first);

    final updatedPaths = List<String>.from(plan.installmentImagePaths)
      ..removeWhere((path) => path == imagePath);

    return byInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePaths: updatedPaths,
    );
  }
}