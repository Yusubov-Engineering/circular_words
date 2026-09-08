import 'package:assets/assets.dart';
import 'package:flutter/widgets.dart';

class const AppImage({
  required final AppRasterAsset asset,
  final BoxFit? fit,
  final double? width,
  final double? height,
  final AlignmentGeometry alignment = Alignment.center,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset.path,
      fit: fit,
      package: asset.packageName,
      width: width,
      height: height,
      alignment: alignment,
    );
  }
}
