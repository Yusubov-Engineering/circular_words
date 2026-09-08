import 'package:assets/assets.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_graphics/vector_graphics.dart';

class const AppVectorImage({
  required final AppVectorAsset asset,
  final BoxFit fit = BoxFit.contain,
  final double? width,
  final double? height,
  final AlignmentGeometry alignment = Alignment.center,
  final Color? color,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VectorGraphic(
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      loader: AssetBytesLoader(asset.path, packageName: asset.packageName),
    );
  }
}
