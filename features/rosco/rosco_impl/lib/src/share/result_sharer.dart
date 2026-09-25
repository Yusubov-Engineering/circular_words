import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// {@template result_sharer}
/// Hands a finished round to the platform's share sheet.
///
/// A contract of its own so the plugin stays out of the screen and a test can
/// substitute a fake; the player chooses the destination — Instagram,
/// WhatsApp, Messages — from the sheet the platform shows.
/// {@endtemplate}
abstract interface class ResultSharer {
  /// Shares [image] (a PNG) with [text] beside it.
  ///
  /// [origin] anchors the sheet on iPad, where it is a popover.
  Future<void> share({
    required Uint8List image,
    required String text,
    Rect? origin,
  });
}

/// {@macro result_sharer}
final class SharePlusResultSharer implements ResultSharer {
  const SharePlusResultSharer();

  @override
  Future<void> share({
    required Uint8List image,
    required String text,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(image, mimeType: 'image/png')],
        // `fromData` drops the name on every platform but the web, and some
        // share targets refuse a file with no extension.
        fileNameOverrides: const ['circular-words.png'],
        sharePositionOrigin: origin,
      ),
    );
  }
}
