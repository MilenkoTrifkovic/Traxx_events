import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/guest_model.dart';

/// Card displaying guest information
class GuestInfoCard extends StatelessWidget {
  final GuestModel guest;

  const GuestInfoCard({
    super.key,
    required this.guest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', guest.name ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Email', guest.email ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Batch ID', guest.batchId ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
