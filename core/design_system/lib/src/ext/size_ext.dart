import 'package:flutter/widgets.dart';

extension SizeExt on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
}
