import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/demographic_response_model.dart';

/// Widget to display demographics response details in read-only mode
class DemographicsResponseView extends StatelessWidget {
  final DemographicResponseModel response;

  const DemographicsResponseView({
    super.key,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    if (response.answers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No responses yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: response.answers.map((answer) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question text
              Text(
                answer.questionText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              
              // Answer value
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _formatAnswer(answer),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatAnswer(DemographicAnswer answer) {
    if (answer.answer == null) return 'No answer provided';
    
    // Handle different answer types
    if (answer.answer is List) {
      final list = answer.answer as List;
      if (list.isEmpty) return 'No answer provided';
      return list.join(', ');
    }
    
    return answer.answer.toString();
  }
}
