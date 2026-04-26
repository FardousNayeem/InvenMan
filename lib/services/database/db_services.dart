import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/history.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';

import 'package:invenman/app/actions/sell_item_action.dart';
import 'package:invenman/app/actions/import_backup_action.dart';
import 'package:invenman/app/actions/delete_all_data_action.dart';
import 'package:invenman/app/actions/installment_payment_action.dart';
import 'package:invenman/app/actions/update_installment_documents_action.dart';

import 'package:invenman/services/backup/backup_models.dart';
import 'package:invenman/services/backup/backup_service.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';
import 'package:invenman/services/repositories/item_repository.dart';
import 'package:invenman/services/repositories/sale_repository.dart';

class DBHelper {
  static bool _registeredDatabaseCallbacks = false;

  static void _ensureDatabaseCallbacksRegistered() {
    if (_registeredDatabaseCallbacks) return;

    AppDatabase.registerNormalizeExistingInstallmentValues(
      InstallmentRepository.normalizeExistingInstallmentValues,
    );

    _registeredDatabaseCallbacks = true;
  }

  static Future<sqflite.Database> get db async {
    _ensureDatabaseCallbacksRegistered();
    return AppDatabase.db;
  }

  static Future<String> getDatabasePath() {
    _ensureDatabaseCallbacksRegistered();
    return AppDatabase.getDatabasePath();
  }

  static Future<void> close() {
    return AppDatabase.close();
  }

  static Future<File> exportDatabaseToPath(String destinationPath) {
    _ensureDatabaseCallbacksRegistered();
    return BackupService.exportDatabaseToPath(destinationPath);
  }

  static Future<File> exportBackupPackageToPath(String destinationPath) {
    _ensureDatabaseCallbacksRegistered();
    return BackupService.exportBackupPackageToPath(destinationPath);
  }

  static Future<DatabaseImportSummary> importBackupPackageFromPath(
    String sourcePath,
  ) {
    _ensureDatabaseCallbacksRegistered();
    return ImportBackupAction.execute(sourcePath);
  }

  static Future<DatabaseImportSummary> importDatabaseFromPath(
    String sourcePath,
  ) {
    _ensureDatabaseCallbacksRegistered();
    return BackupService.importDatabaseFromPath(sourcePath);
  }

  static Future<void> deleteAllAppData() {
    _ensureDatabaseCallbacksRegistered();
    return DeleteAllAppDataAction.execute();
  }

  static Future<void> clearAllData() {
    _ensureDatabaseCallbacksRegistered();
    return DeleteAllAppDataAction.clearAllData();
  }

  static Future<List<String>> fetchDistinctCategories() {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.fetchDistinctCategories();
  }

  static Future<List<String>> fetchDistinctBrands() {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.fetchDistinctBrands();
  }

  static Future<void> insertItem(Item item) {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.insertItem(item);
  }

  static Future<void> updateItem(Item item) {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.updateItem(item);
  }

  static Future<void> deleteItem(int id, String name) {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.deleteItem(id, name);
  }

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.fetchItems(sortBy: sortBy);
  }

  static Future<Item?> fetchItemById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return ItemRepository.fetchItemById(id);
  }

  static Future<void> insertSaleRecord(
    SaleRecord sale, {
    double? downPayment,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return SaleRepository.insertSaleRecord(
      sale,
      downPayment: downPayment,
    );
  }

  static Future<List<SaleRecord>> fetchSaleRecords() {
    _ensureDatabaseCallbacksRegistered();
    return SaleRepository.fetchSaleRecords();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return SaleRepository.fetchSaleRecordById(id);
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
  }) {
    _ensureDatabaseCallbacksRegistered();

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

  static Future<void> logHistory(
    String itemName,
    String action,
    String details, {
    sqflite.DatabaseExecutor? executor,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return HistoryRepository.logHistory(
      itemName: itemName,
      action: action,
      details: details,
      executor: executor,
    );
  }

  static Future<List<HistoryEntry>> fetchHistoryEntries() {
    _ensureDatabaseCallbacksRegistered();
    return HistoryRepository.fetchHistoryEntries();
  }

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) {
    _ensureDatabaseCallbacksRegistered();
    return InstallmentRepository.fetchInstallmentPlans(sortBy: sortBy);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return InstallmentRepository.fetchInstallmentPlanById(id);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(
    int saleRecordId,
  ) {
    _ensureDatabaseCallbacksRegistered();
    return InstallmentRepository.fetchInstallmentPlanBySaleRecordId(
      saleRecordId,
    );
  }

  static Future<List<InstallmentPayment>> fetchInstallmentPayments(
    int installmentPlanId,
  ) {
    _ensureDatabaseCallbacksRegistered();
    return InstallmentRepository.fetchInstallmentPayments(installmentPlanId);
  }

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return RecordInstallmentPaymentAction.execute(
      installmentPaymentId: installmentPaymentId,
      amountPaid: amountPaid,
      paidDate: paidDate,
      note: note,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsBySaleRecordId({
    required int saleRecordId,
    required List<String> imagePaths,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return UpdateInstallmentDocumentsAction.bySaleRecordId(
      saleRecordId: saleRecordId,
      imagePaths: imagePaths,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsByInstallmentPlanId({
    required int installmentPlanId,
    required List<String> imagePaths,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return UpdateInstallmentDocumentsAction.byInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePaths: imagePaths,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentBySaleRecordId({
    required int saleRecordId,
    required String imagePath,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return UpdateInstallmentDocumentsAction.removeBySaleRecordId(
      saleRecordId: saleRecordId,
      imagePath: imagePath,
    );
  }
  
  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentByInstallmentPlanId({
    required int installmentPlanId,
    required String imagePath,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return UpdateInstallmentDocumentsAction.removeByInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePath: imagePath,
    );
  }
}