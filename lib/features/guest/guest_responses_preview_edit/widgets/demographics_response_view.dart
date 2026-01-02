import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/demographic_response_model.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppText.styledBodyMedium(
          context,
          'No responses yet',
          color: AppColors.textMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: response.answers.map((answer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question text with icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText.styledLabelMedium(
                      context,
                      answer.questionText,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Answer value with better styling
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: AppText.styledBodyMedium(
                  context,
                  _formatAnswer(answer),
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
