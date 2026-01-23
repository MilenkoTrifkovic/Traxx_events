import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/controllers/buy_credits_controller.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

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
              AppText.styledHeadingLarge(
                context,
                'Buy Credits',
                color: AppColors.primaryAccent,
              ),
              const SizedBox(height: 8),
              AppText.styledBodyLarge(
                context,
                'Purchase credits to unlock premium features and services',
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 24),

              // Test Checkout Button
              AppPrimaryButton(
                text: 'Call Checkout Function',
                onPressed: () => controller.callCheckoutFunction(),
                icon: Icons.payment,
                width: 250,
              ),
              const SizedBox(height: 40),

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
                      onPurchase: () => controller.callCheckoutFunction(amount: package.price),
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 40),

              // Info Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        AppText.styledHeadingSmall(
                          context,
                          'How Credits Work',
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.check_circle_outline,
                      'Credits never expire',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.check_circle_outline,
                      'Use credits for premium event features',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.check_circle_outline,
                      'Secure payment powered by Stripe',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.success,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppText.styledBodyMedium(
            context,
            text,
            color: AppColors.black,
          ),
        ),
      ],
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
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: package.isPopular ? AppColors.primaryAccent : AppColors.borderSubtle,
          width: package.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Popular Badge
          if (package.isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: AppText.styledLabelSmall(
                  context,
                  'BEST VALUE',
                  color: Colors.white,
                  weight: FontWeight.bold,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credits Count
                AppText.styledHeadingLarge(
                  context,
                  '${package.credits}',
                  color: AppColors.primaryAccent,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText.styledBodyMedium(
                  context,
                  'Credits',
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText.styledHeadingMedium(
                      context,
                      package.priceFormatted,
                      weight: FontWeight.bold,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: AppText.styledBodySmall(
                        context,
                        '(\$${package.pricePerCredit.toStringAsFixed(2)} per credit)',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                AppText.styledBodyMedium(
                  context,
                  package.description,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 24),

                // Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: package.isPopular
                          ? AppColors.primaryAccent
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText.styledBodyMedium(
                      context,
                      'Purchase',
                      color: Colors.white,
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
