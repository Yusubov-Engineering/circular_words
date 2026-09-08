import 'package:app_localization/app_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:speech_api/speech_api.dart';

/// Turns a reason the microphone is unusable into a sentence.
///
/// Every message names the way out — typing — because none of these states is
/// something the player can fix from this screen, and a dead end with no
/// instruction reads as a broken game rather than a game being played a
/// different way.
extension SpeechUnavailableReasonL10n on SpeechUnavailableReason {
  String message(BuildContext context) {
    final l10n = context.localization;

    return switch (this) {
      SpeechUnavailableReason.permissionDenied => l10n.micDenied,
      SpeechUnavailableReason.noRecognizer => l10n.micNoRecognizer,
      SpeechUnavailableReason.restricted => l10n.micRestricted,
      SpeechUnavailableReason.unknown => l10n.micUnavailable,
    };
  }
}
