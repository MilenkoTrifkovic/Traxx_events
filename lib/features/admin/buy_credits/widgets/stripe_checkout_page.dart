import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
import 'dart:js' as js;
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class StripeCheckoutPage extends StatefulWidget {
  final CreditPackage package;
  final String clientSecret;

  const StripeCheckoutPage({
    super.key,
    required this.package,
    required this.clientSecret,
  });

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  String? _errorMessage;
  late final String _checkoutElementId;
  bool _isRegistered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkoutElementId = 'stripe-checkout-${DateTime.now().millisecondsSinceEpoch}';
    print('🟢 StripeCheckoutPage initialized with clientSecret: ${widget.clientSecret.substring(0, 20)}...');
    
    // Register view factory immediately
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_isRegistered) return;
    
    try {
      print('🟢 Registering view factory: $_checkoutElementId');
      
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _checkoutElementId,
        (int viewId) {
          print('🟢 View factory creating div: $_checkoutElementId');
          final div = html.DivElement()
            ..id = _checkoutElementId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.minHeight = '400px';
          return div;
        },
      );
      
      _isRegistered = true;
      print('🟢 View registered successfully');
      
      // Initialize Stripe after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _initializeStripeCheckout();
      });
      
    } catch (e) {
      print('🔴 Error registering view: $e');
      setState(() {
        _errorMessage = 'Failed to initialize payment form: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeStripeCheckout() {
    try {
      print('🟢 Calling initStripeCheckout JS function...');
      js.context.callMethod('initStripeCheckout', [
        widget.clientSecret,
        _checkoutElementId,
      ]);
      setState(() {
        _isLoading = false;
      });
      print('🟢 Stripe checkout initialization requested');
    } catch (e) {
      print('🔴 Error calling initStripeCheckout: $e');
      setState(() {
        _errorMessage = 'Failed to initialize Stripe: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText.styledHeadingMedium(
          context,
          'Complete Payment',
          weight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Package summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.styledBodySmall(
                            context,
                            'Credits',
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          AppText.styledHeadingSmall(
                            context,
                            '${widget.package.credits}',
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText.styledBodySmall(
                            context,
                            'Total',
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          AppText.styledHeadingSmall(
                            context,
                            widget.package.priceFormatted,
                            weight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                
                // Stripe checkout container - fixed height
                Container(
                  height: 450,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textMuted.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: HtmlElementView(viewType: _checkoutElementId),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Secure payment notice
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    AppText.styledBodySmall(
                      context,
                      'Secure payment powered by Stripe',
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
