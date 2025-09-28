import 'package:flutter/widgets.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

double calculateItemWidth(
    BuildContext context, int itemCount, double maxWidth) {
  maxWidth = maxWidth - ((itemCount - 1) * 4);
  final isPhone = ScreenSize.isPhone(context);
  final maxColumns = isPhone ? 3 : 4;
  int columns;
  if (itemCount <= 2) {
    return (maxWidth / itemCount);
  }
  if (itemCount <= maxColumns) {
    columns = itemCount;
  } else {
    if (itemCount % maxColumns == 0) {
      columns = maxColumns;
    } else if (itemCount % 2 == 0) {
      columns = 2;
    } else if (itemCount % 3 == 0) {
      columns = 3;
    } else {
      columns = maxColumns;
    }
  }
  return (maxWidth / columns);
}
