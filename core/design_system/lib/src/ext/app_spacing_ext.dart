import 'package:flutter/widgets.dart';

extension AppSpacingExt on num {
  SizedBox get space => SizedBox.square(dimension: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
  SizedBox get verticalSpace => SizedBox(height: toDouble());
}
