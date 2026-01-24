import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/payment_transaction.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';

/// Global controller for managing payment history and events balance.
/// 
/// This controller is responsible for:
/// - Fetching payment history for the organisation
/// - Calculating total purchased events
/// - Providing getters for events balance across the app
/// 
/// The actual validation for creating events happens on the backend.
/// This controller provides the data for UI/UX purposes.
class PaymentHistoryController extends GetxController {
  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<PaymentTransaction> paymentHistory = <PaymentTransaction>[].obs;
  
  // Cached totals
  final RxInt totalPurchasedEvents = 0.obs;

  /// Get organisation controller
  OrganisationController? get _orgController {
    try {
      return Get.find<OrganisationController>();
    } catch (e) {
      print('⚠️ OrganisationController not found: $e');
      return null;
    }
  }

  /// Organisation ID from the organisation controller
  String? get organisationId => _orgController?.organisationId;

  @override
  void onInit() {
    super.onInit();
    // Automatically fetch payment history when controller is initialized
    fetchPaymentHistory();
  }

  // ============================================
  // GETTERS - Use these across the app
  // ============================================

  /// Total number of events purchased by this organisation
  int get purchasedEvents => totalPurchasedEvents.value;

  /// Check if there are any transactions
  bool get hasTransactions => paymentHistory.isNotEmpty;

  /// Number of transactions
  int get transactionCount => paymentHistory.length;

  /// Check if payment history is currently loading
  bool get isLoadingHistory => isLoading.value;

  /// Get all payment transactions (read-only)
  List<PaymentTransaction> get transactions => paymentHistory.toList();

  // ============================================
  // METHODS
  // ============================================

  /// Fetches payment history for the current organisation.
  /// Also calculates total purchased events.
  Future<void> fetchPaymentHistory() async {
    final orgId = organisationId;
    if (orgId == null || orgId.isEmpty) {
      print('⚠️ No organisation ID available for fetching payment history');
      paymentHistory.clear();
      totalPurchasedEvents.value = 0;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔵 Fetching payment history for organisation: $orgId');

      final callable = FirebaseFunctions.instance.httpsCallable('getPaymentHistory');
      final result = await callable.call({'organisationId': orgId});
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final List<dynamic> paymentsData = data['payments'] ?? [];
        final payments = paymentsData
            .map((json) => PaymentTransaction.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        paymentHistory.value = payments;
        
        // Calculate total purchased events from completed payments
        _calculateTotalPurchasedEvents();
        
        print('✅ Loaded ${payments.length} payment(s), Total events: ${totalPurchasedEvents.value}');
      } else {
        throw Exception('Failed to fetch payment history');
      }
    } on FirebaseFunctionsException catch (e) {
      errorMessage.value = e.message ?? 'Failed to fetch payment history';
      print('🔴 Firebase Functions error: ${e.code} - ${e.message}');
      paymentHistory.clear();
      totalPurchasedEvents.value = 0;
    } catch (e) {
      errorMessage.value = e.toString();
      print('🔴 Error fetching payment history: $e');
      paymentHistory.clear();
      totalPurchasedEvents.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  /// Refreshes the payment history
  Future<void> refreshPaymentHistory() async {
    await fetchPaymentHistory();
  }

  /// Calculate total purchased events from completed payments only
  void _calculateTotalPurchasedEvents() {
    int total = 0;
    for (final payment in paymentHistory) {
      // Only count completed/successful payments
      final status = payment.paymentStatus.toLowerCase();
      if (status == 'paid' || 
          status == 'complete' || 
          status == 'completed' ||
          status == 'succeeded') {
        total += payment.events;
      }
    }
    totalPurchasedEvents.value = total;
  }

  /// Clear all payment data (useful for logout)
  void clearPaymentData() {
    paymentHistory.clear();
    totalPurchasedEvents.value = 0;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    clearPaymentData();
    super.onClose();
  }
}
