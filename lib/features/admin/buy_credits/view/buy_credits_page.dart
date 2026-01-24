import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/controllers/buy_credits_controller.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/widgets/transaction_history_widget.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class BuyCreditsPage extends StatelessWidget {
  const BuyCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BuyCreditsController());

    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              // AppText.styledHeadingLarge(
              //   context,
              //   'Buy Events',
              //   color: AppColors.primaryAccent,
              // ),
              // const SizedBox(height: 8),
              // AppText.styledBodyLarge(
              //   context,
              //   'Purchase event packages to create and manage your events',
              //   color: AppColors.textMuted,
              // ),
              // const SizedBox(height: 24),

              // // Test Checkout Button
              // AppPrimaryButton(
              //   text: 'Call Checkout Function',
              //   onPressed: () => controller.callCheckoutFunction(),
              //   icon: Icons.payment,
              //   width: 250,
              // ),
              // const SizedBox(height: 40),

              // Credit Packages
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: controller.creditPackages.map((package) {
                    return _CreditPackageCard(
                      package: package,
                      onPurchase: () => controller.callCheckoutFunction(
                          amount: package.price),
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 40),

              // Transaction History
              TransactionHistoryWidget(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditPackageCard extends StatelessWidget {
  final CreditPackage package;
  final VoidCallback onPurchase;

  const _CreditPackageCard({
    required this.package,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = package.isPopular;
    final backgroundColor = isPrimary
        ? const Color(0xFF3B5998) // Blue color for popular package
        : AppColors.surface(context);
    final textColor = isPrimary ? Colors.white : AppColors.black;
    final mutedTextColor =
        isPrimary ? Colors.white.withOpacity(0.9) : AppColors.textMuted;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary ? const Color(0xFF3B5998) : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Popular Badge
          if (isPrimary)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C4370),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText.styledLabelSmall(
                    context,
                    'Most Popular',
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Package Name
                AppText.styledHeadingMedium(
                  context,
                  package.name,
                  color: textColor,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 20),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.styledHeadingLarge(
                      context,
                      package.priceFormatted,
                      color: textColor,
                      weight: FontWeight.bold,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppText.styledBodyMedium(
                        context,
                        'per event',
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Events count and total
                if (package.events > 1) ...[
                  AppText.styledBodyMedium(
                    context,
                    '${package.events} events - ${package.description}',
                    color: mutedTextColor,
                  ),
                  const SizedBox(height: 8),
                  AppText.styledBodyMedium(
                    context,
                    'Total: ${package.totalPriceFormatted} (Save ${package.savingsFormatted})',
                    color: mutedTextColor,
                    weight: FontWeight.w600,
                  ),
                ] else ...[
                  AppText.styledBodyMedium(
                    context,
                    package.description,
                    color: mutedTextColor,
                  ),
                ],

                const SizedBox(height: 32),

                // Features List
                ...package.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            color: isPrimary ? Colors.white : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText.styledBodyMedium(
                              context,
                              feature,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPrimary ? Colors.white : const Color(0xFF3B5998),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText.styledBodyMedium(
                      context,
                      'Buy Now',
                      // isPrimary
                          // ? (package.events == 1
                          //     ? 'Get Started'
                          //     : 'Get Started')
                          // : (package.events == 100
                          //     ? 'Contact Sales'
                          //     : 'Get Started'),
                      color: isPrimary ? const Color(0xFF3B5998) : Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
