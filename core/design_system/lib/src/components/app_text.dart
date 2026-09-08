import 'package:flutter/widgets.dart';

class const AppText({
  required final String title,
  final TextStyle? style,
  final TextOverflow? overflow,
  final int? maxLines,
  final TextAlign? textAlign,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
