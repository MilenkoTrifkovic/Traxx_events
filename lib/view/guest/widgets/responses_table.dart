import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class ResponsesTable extends StatefulWidget {
  final List<Map<String, String>> responses;
  const ResponsesTable({super.key, required this.responses});

  @override
  State<ResponsesTable> createState() => _ResponsesTableState();
}

class _ResponsesTableState extends State<ResponsesTable> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary(context).withOpacity(0.1),
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.primary(context).withOpacity(0.05);
              }
              return null;
            }),
            columnSpacing: 24,
            horizontalMargin: 12,
            columns: widget.responses.first.keys
                .map((e) => DataColumn(
                      label: AppText.styledBodyMedium(
                        context,
                        e,
                        weight: FontWeight.bold,
                      ),
                    ))
                .toList(),
            rows: widget.responses
                .map((e) => DataRow(
                      cells: e.values
                          .map((value) => DataCell(
                                AppText.styledBodyMedium(context, value),
                              ))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
