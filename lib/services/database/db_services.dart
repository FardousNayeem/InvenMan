import 'dart:io';

import 'package:invenman/app/actions/delete_all_data_action.dart';
import 'package:invenman/app/actions/import_backup_action.dart';

import 'package:invenman/models/backup_models.dart';
import 'package:invenman/models/history.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';

import 'package:invenman/services/backup/backup_service.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/history/history_service.dart';
import 'package:invenman/services/installment/installment_service.dart';
import 'package:invenman/services/inventory/inventory_service.dart';
import 'package:invenman/services/repositories/installment_repository.dart';
import 'package:invenman/services/sales/sales_service.dart';

class DBHelper {
  static bool _registeredDatabaseCallbacks = false;

  // ---------------------------------------------------------------------------
  // Database lifecycle
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Backup / import / export
  //
  // Still kept here for compatibility. Later these should move behind
  // BackupAppService and screens should call BackupAppService directly.
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // App-level destructive operations
  //
  // Still kept here for compatibility. Later settings should call the app-level
  // backup/reset service directly.
  // ---------------------------------------------------------------------------

  static Future<void> deleteAllAppData() {
    _ensureDatabaseCallbacksRegistered();
    return DeleteAllAppDataAction.execute();
  }

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.fetchItems(sortBy: sortBy);
  }

  static Future<Item?> fetchItemById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.fetchItemById(id);
  }

  static Future<List<String>> fetchDistinctCategories() {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.fetchDistinctCategories();
  }

  static Future<List<String>> fetchDistinctBrands() {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.fetchDistinctBrands();
  }

  static Future<void> insertItem(Item item) {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.insertItem(item);
  }

  static Future<void> updateItem(Item item) {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.updateItem(item);
  }

  static Future<void> deleteItem(int id, String name) {
    _ensureDatabaseCallbacksRegistered();
    return InventoryService.deleteItem(id, name);
  }

  // ---------------------------------------------------------------------------
  // Sales
  // ---------------------------------------------------------------------------

  static Future<List<SaleRecord>> fetchSaleRecords() {
    _ensureDatabaseCallbacksRegistered();
    return SalesService.fetchSaleRecords();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return SalesService.fetchSaleRecordById(id);
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

    return SalesService.sellItem(
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

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  static Future<List<HistoryEntry>> fetchHistoryEntries() {
    _ensureDatabaseCallbacksRegistered();
    return HistoryService.fetchEntries();
  }

  // ---------------------------------------------------------------------------
  // Installments
  // ---------------------------------------------------------------------------

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) {
    _ensureDatabaseCallbacksRegistered();

    return InstallmentService.fetchInstallmentPlans(
      sortBy: sortBy,
    );
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) {
    _ensureDatabaseCallbacksRegistered();
    return InstallmentService.fetchInstallmentPlanById(id);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(
    int saleRecordId,
  ) {
    _ensureDatabaseCallbacksRegistered();

    return InstallmentService.fetchInstallmentPlanBySaleRecordId(
      saleRecordId,
    );
  }

  static Future<List<InstallmentPayment>> fetchInstallmentPayments(
    int installmentPlanId,
  ) {
    _ensureDatabaseCallbacksRegistered();

    return InstallmentService.fetchInstallmentPayments(
      installmentPlanId,
    );
  }

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) {
    _ensureDatabaseCallbacksRegistered();

    return InstallmentService.saveInstallmentPayment(
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

    return InstallmentService.updateInstallmentDocumentsBySaleRecordId(
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

    return InstallmentService.updateInstallmentDocumentsByInstallmentPlanId(
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

    return InstallmentService.removeInstallmentDocumentBySaleRecordId(
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

    return InstallmentService.removeInstallmentDocumentByInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePath: imagePath,
    );
  }
}