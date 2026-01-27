import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/controllers/buy_credits_controller.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/payment_transaction.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final BuyCreditsController controller;

  const TransactionHistoryWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(ScreenSize.pick(
              context,
              phone: 20.0,
              desktop: 32.0,
            )),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSubtle.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: ScreenSize.isPhone(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderContent(context),
                      const SizedBox(height: 16),
                      _buildRefreshButton(context),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderContent(context),
                      _buildRefreshButton(context),
                    ],
                  ),
          ),

          // Summary Stats Section
          Obx(() => _buildSummaryStats(context)),

          // Content Section
          Padding(
            padding: EdgeInsets.all(ScreenSize.pick(
              context,
              phone: 16.0,
              desktop: 32.0,
            )),
            child: Obx(() {
              if (controller.isLoadingHistory.value) {
                return _buildLoadingState(context);
              }

              if (controller.paymentHistory.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildTransactionList(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.receipt_long,
            color: AppColors.primaryAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.styledHeadingMedium(context, 'Transactions',
                weight: FontWeight.bold,
                color: AppColors.black,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Obx(() => AppText.styledBodySmall(
                  context,
                  controller.paymentHistory.isEmpty
                      ? 'No transactions yet'
                      : '${controller.paymentHistory.length} transaction${controller.paymentHistory.length == 1 ? '' : 's'}',
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.refreshPaymentHistory(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 18,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              AppText.styledBodySmall(
                context,
                'Refresh',
                color: AppColors.primaryAccent,
                weight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    
    // Access reactive values
    final purchased = controller.totalPurchasedEvents;
    final used = controller.totalUsedEvents;
    final left = controller.eventsLeft;
    final moneySpent = controller.totalMoneySpentFormatted;

    return Container(
      padding: EdgeInsets.all(isPhone ? 16.0 : 24.0),
      margin: EdgeInsets.symmetric(
        horizontal: isPhone ? 16.0 : 32.0,
        vertical: isPhone ? 12.0 : 16.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withOpacity(0.08),
            AppColors.primaryAccent.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.15),
        ),
      ),
      child: isPhone
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.shopping_cart_outlined,
                        label: 'Purchased',
                        value: '$purchased',
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.event_available,
                        label: 'Used',
                        value: '$used',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.event_note,
                        label: 'Remaining',
                        value: '$left',
                        color: left > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.attach_money,
                        label: 'Total Spent',
                        value: moneySpent,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.shopping_cart_outlined,
                    label: 'Events Purchased',
                    value: '$purchased',
                    color: AppColors.primaryAccent,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.event_available,
                    label: 'Events Used',
                    value: '$used',
                    color: Colors.orange,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.event_note,
                    label: 'Events Remaining',
                    value: '$left',
                    color: left > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    highlight: true,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.attach_money,
                    label: 'Total Spent',
                    value: moneySpent,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: highlight
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            )
          : null,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          AppText.styledHeadingMedium(
            context,
            value,
            weight: FontWeight.bold,
            color: color,
          ),
          const SizedBox(height: 4),
          AppText.styledBodySmall(
            context,
            label,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppColors.borderSubtle.withOpacity(0.5),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppText.styledBodyMedium(
              context,
              'Loading transactions...',
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.primaryAccent.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            AppText.styledHeadingSmall(
              context,
              'No transactions yet',
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 12),
            AppText.styledBodyMedium(
              context,
              'Your purchase history will appear here',
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            AppText.styledBodySmall(
              context,
              'Start by purchasing an event package above',
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    return Column(
      children: controller.paymentHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final transaction = entry.value;
        final isLast = index == controller.paymentHistory.length - 1;
        return _buildTransactionCard(context, transaction, isLast);
      }).toList(),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    PaymentTransaction transaction,
    bool isLast,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm a');
    final isPhone = ScreenSize.isPhone(context);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: EdgeInsets.all(isPhone ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          isPhone
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.styledBodyLarge(
                                context,
                                transaction.packageName,
                                weight: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  AppText.styledBodySmall(
                                    context,
                                    dateFormat.format(transaction.createdAt),
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusChip(context, transaction.statusFormatted),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Package Name and Status
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primaryAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.styledBodyLarge(
                                  context,
                                  transaction.packageName,
                                  weight: FontWeight.w600,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    AppText.styledBodySmall(
                                      context,
                                      dateFormat.format(transaction.createdAt),
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    AppText.styledBodySmall(
                                      context,
                                      timeFormat.format(transaction.createdAt),
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Badge
                    _buildStatusChip(context, transaction.statusFormatted),
                  ],
                ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: AppColors.borderSubtle.withOpacity(0.3),
          ),

          const SizedBox(height: 20),

          // Details Grid - Responsive
          isPhone
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      context,
                      icon: Icons.event_available,
                      label: 'Events',
                      value: '${transaction.events}',
                      valueColor: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      context,
                      icon: Icons.payments_outlined,
                      label: 'Amount',
                      value: transaction.amountFormatted,
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      context,
                      icon: Icons.person_outline,
                      label: 'Purchased by',
                      value: transaction.userEmail,
                      valueColor: AppColors.textMuted,
                      truncate: true,
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Events
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        icon: Icons.event_available,
                        label: 'Events',
                        value: '${transaction.events}',
                        valueColor: AppColors.primaryAccent,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderSubtle.withOpacity(0.3),
                    ),
                    // Amount
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        icon: Icons.payments_outlined,
                        label: 'Amount',
                        value: transaction.amountFormatted,
                        valueColor: AppColors.success,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderSubtle.withOpacity(0.3),
                    ),
                    // User
                    Expanded(
                      flex: 2,
                      child: _buildDetailItem(
                        context,
                        icon: Icons.person_outline,
                        label: 'Purchased by',
                        value: transaction.userEmail,
                        valueColor: AppColors.textMuted,
                        truncate: true,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          // Transaction ID Row with Copy Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                AppText.styledBodySmall(
                  context,
                  'Transaction ID:',
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    transaction.transactionId,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: transaction.transactionId),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Transaction ID copied to clipboard'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.primaryAccent,
                      ),
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

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool truncate = false,
  }) {
    final isPhone = ScreenSize.isPhone(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              AppText.styledBodySmall(
                context,
                label,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          truncate
              ? Tooltip(
                  message: value,
                  child: AppText.styledBodyMedium(
                    context,
                    _truncateString(
                      value,
                      isPhone ? 30 : 25,
                    ),
                    color: valueColor,
                    weight: FontWeight.w600,
                  ),
                )
              : AppText.styledBodyMedium(
                  context,
                  value,
                  color: valueColor,
                  weight: FontWeight.w600,
                ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'failed':
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red;
        icon = Icons.error;
        break;
      case 'refunded':
        backgroundColor = Colors.purple.withOpacity(0.15);
        textColor = Colors.purple;
        icon = Icons.refresh;
        break;
      default:
        backgroundColor = AppColors.textMuted.withOpacity(0.15);
        textColor = AppColors.textMuted;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          AppText.styledBodySmall(
            context,
            status,
            color: textColor,
            weight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
