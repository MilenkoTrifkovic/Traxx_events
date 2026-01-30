import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/payment_transaction.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/controller/global_controllers/payment_history_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';

class BuyCreditsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Get global payment history controller
  PaymentHistoryController? get _paymentHistoryController {
    try {
      return Get.find<PaymentHistoryController>();
    } catch (e) {
      print('⚠️ PaymentHistoryController not found: $e');
      return null;
    }
  }

  // Get event list controller for used events count
  EventListController? get _eventListController {
    try {
      return Get.find<EventListController>();
    } catch (e) {
      print('⚠️ EventListController not found: $e');
      return null;
    }
  }

  // ============================================
  // GETTERS - Delegate to global controller
  // ============================================

  /// Check if payment history is loading
  RxBool get isLoadingHistory =>
      _paymentHistoryController?.isLoading ?? false.obs;

  /// Get payment history from global controller
  RxList<PaymentTransaction> get paymentHistory =>
      _paymentHistoryController?.paymentHistory ?? <PaymentTransaction>[].obs;

  /// Total purchased events
  int get totalPurchasedEvents =>
      _paymentHistoryController?.purchasedEvents ?? 0;

  /// Total gifted events
  int get totalGiftedEvents =>
      _paymentHistoryController?.giftedEvents ?? 0;

  /// Total used events (from event list)
  int get totalUsedEvents => _eventListController?.events.length ?? 0;

  /// Events left (purchased + gifted - used)
  int get eventsLeft => (totalPurchasedEvents + totalGiftedEvents) - totalUsedEvents;

  /// Total money spent (in cents) - sum of all completed payments
  int get totalMoneySpentCents {
    if (_paymentHistoryController == null) return 0;
    int total = 0;
    for (final payment in _paymentHistoryController!.paymentHistory) {
      final status = payment.paymentStatus.toLowerCase();
      if (status == 'paid' || 
          status == 'complete' || 
          status == 'completed' ||
          status == 'succeeded') {
        total += payment.amount;
      }
    }
    return total;
  }

  /// Total money spent formatted (e.g., "$1,234.56")
  String get totalMoneySpentFormatted {
    final dollars = totalMoneySpentCents / 100;
    return '\$${dollars.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // Event package options
  final List<CreditPackage> creditPackages = [
    CreditPackage(
      name: 'Single Event',
      events: 1,
      price: 29900, // $299.00 in cents
      description: 'Perfect for one-time events and special occasions',
      features: [
        'Complete guest list management',
        'Seating chart creation',
        'Meal preference tracking',
        'Custom invitation forms',
        'Real-time RSVP tracking',
        'Email support',
      ],
      stripePriceId: 'price_test_1event',
    ),
    CreditPackage(
      name: 'Professional Package',
      events: 50,
      price: 25000, // $250.00 per event in cents
      totalPrice: 1250000, // $12,500.00 total
      savings: 245000, // $2,450.00 savings
      description: 'Perfect for event professionals',
      isPopular: true,
      features: [
        'Everything in Single Event',
        'Priority support',
        'Advanced reporting',
        'Team collaboration tools',
        'Custom branding options',
        'Phone support',
      ],
      stripePriceId: 'price_test_50events',
    ),
    CreditPackage(
      name: 'Enterprise Package',
      events: 100,
      price: 20000, // $200.00 per event in cents
      totalPrice: 2000000, // $20,000.00 total
      savings: 990000, // $9,900.00 savings
      description: 'For large-scale operations',
      features: [
        'Everything in Professional',
        'Dedicated account manager',
        'API access',
        'Custom integrations',
        'White-label options',
        '24/7 priority support',
      ],
      stripePriceId: 'price_test_100events',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Payment history is now handled by global PaymentHistoryController
    // which is initialized in host shell route
  }

  Future<void> callCheckoutFunction({int? amount}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔵 Calling checkout function...');

      // Get current user email
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User must be signed in to purchase credits');
      }

      final userEmail = user.email!;
      print('🔵 User email: $userEmail');

      final queryParams = <String, String>{
        'userEmail': userEmail,
      };

      if (amount != null) {
        // Send the total price (not per-event price)
        final totalAmount = _getTotalAmount(amount);
        queryParams['amount'] = totalAmount.toString();
        print('🔵 Total Amount: $totalAmount');
      }

      final uri = Uri.parse(Constants.checkoutSessionUrl).replace(
        queryParameters: queryParams,
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('🟢 Redirected to checkout session');
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('🔴 Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get the total amount based on per-event price
  int _getTotalAmount(int perEventPrice) {
    // Find the package to get the total price
    final package = creditPackages.firstWhere(
      (pkg) => pkg.price == perEventPrice,
      orElse: () => creditPackages.first,
    );

    // Return total price if available, otherwise calculate it
    return package.totalPrice ?? (perEventPrice * package.events);
  }

  /// Refreshes the payment history via global controller
  Future<void> refreshPaymentHistory() async {
    await _paymentHistoryController?.refreshPaymentHistory();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
