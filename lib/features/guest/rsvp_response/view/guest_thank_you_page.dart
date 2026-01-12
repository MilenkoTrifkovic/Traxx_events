import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

class GuestThankYouPage extends StatelessWidget {
  final String invitationId;
  final String token;

  const GuestThankYouPage({
    super.key,
    required this.invitationId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Thank you!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your RSVP, demographics, and menu selections have been submitted.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Event Details'),
                    onPressed: () {
                      pushAndRemoveAllRoute(
                        AppRoute.guestResponse,
                        context,
                        queryParams: {
                          'invitationId': invitationId,
                          if (token.isNotEmpty) 'token': token,
                          'view': 'details',
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
