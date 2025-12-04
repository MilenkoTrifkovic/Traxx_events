import 'package:flutter/material.dart';

class MenuExpansionPanelWidget {
  static ExpansionPanel buildPanel({
    required bool isExpanded,
    required VoidCallback onHeaderTap,
    required BuildContext context,
  }) {
    return ExpansionPanel(
        isExpanded: isExpanded,
        headerBuilder: (context, isExpanded) {
          return InkWell(
            onTap: onHeaderTap,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  Text('Menu', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          );
        },
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            const minWidth = 200.0;
            const maxColumns = 5;

            int columns = (screenWidth / minWidth).floor();
            columns = columns.clamp(1, maxColumns);

            final itemWidth = screenWidth / columns;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: itemWidth,
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      color: Colors.blue,
                    ),
                  ),
                );
              }),
            );
          },
        ));
  }
}
