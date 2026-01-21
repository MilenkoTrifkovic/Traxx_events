import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
import 'package:traxx_wepapp/theme/constants.dart';

class BuyCreditsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Credit package options
  // TODO: Replace these with your actual Stripe Price IDs from your Stripe Dashboard
  final List<CreditPackage> creditPackages = [
    CreditPackage(
      credits: 100,
      price: 9999, // $99.99 in cents
      description: '1 Event',
      stripePriceId:
          'price_test_100credits', // Replace with your actual Stripe Price ID
    ),
    CreditPackage(
      credits: 500,
      price: 39999, // $399.99 in cents
      description: '5 Events',
      isPopular: true,
      stripePriceId:
          'price_test_500credits', // Replace with your actual Stripe Price ID
    ),
    CreditPackage(
      credits: 1000,
      price: 69999, // $699.99 in cents
      description: '10 Events',
      stripePriceId:
          'price_test_1000credits', // Replace with your actual Stripe Price ID
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Initialize any necessary data
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
        queryParams['amount'] = amount.toString();
        print('🔵 Amount: $amount');
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

  @override
  void onClose() {
    super.onClose();
  }
}
