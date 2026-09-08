import 'package:app_localization/app_localization.dart';
import 'package:flutter/widgets.dart';

import '../domain/rosco_failure.dart';

/// Turns a failure into a sentence.
///
/// A controller has no `BuildContext` and so cannot localize; failures travel
/// as values and become words here, at the only layer that can. The switch is
/// exhaustive over the sealed hierarchy, so a new failure kind fails to
/// compile rather than silently rendering nothing.
extension RoscoFailureL10n on RoscoFailure {
  String message(BuildContext context) {
    final l10n = context.localization;

    return switch (this) {
      RoscoLevelUnavailable() => l10n.roscoLevelUnavailable,
      RoscoWordBankMalformed() => l10n.roscoWordBankBroken,
      RoscoUnknownFailure() => l10n.errorUnknown,
    };
  }
}
