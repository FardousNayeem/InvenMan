import 'package:invenman/app/actions/installment_payment_action.dart';
import 'package:invenman/app/actions/update_installment_documents_action.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class InstallmentService {
  const InstallmentService._();

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) {
    return InstallmentRepository.fetchInstallmentPlans(sortBy: sortBy);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) {
    return InstallmentRepository.fetchInstallmentPlanById(id);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(
    int saleRecordId,
  ) {
    return InstallmentRepository.fetchInstallmentPlanBySaleRecordId(
      saleRecordId,
    );
  }

  static Future<List<InstallmentPayment>> fetchInstallmentPayments(
    int installmentPlanId,
  ) {
    return InstallmentRepository.fetchInstallmentPayments(installmentPlanId);
  }

  // ---------------------------------------------------------------------------
  // Workflows
  // ---------------------------------------------------------------------------

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) {
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
    return UpdateInstallmentDocumentsAction.removeByInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePath: imagePath,
    );
  }
}