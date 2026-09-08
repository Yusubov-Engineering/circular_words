import 'package:app_localization/app_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';

/// Turns a level into the sentence beside its code.
///
/// A controller has no `BuildContext` and so cannot localize; this runs at the
/// only layer that can. The CEFR code itself (`A1`, `B2`) is deliberately not
/// translated — it is identical in every language, and `CefrLevel.label`
/// already provides it.
extension CefrLevelL10n on CefrLevel {
  String description(BuildContext context) {
    final l10n = context.localization;

    // Exhaustive over the enum: a seventh level would fail to compile here
    // rather than silently render an empty subtitle.
    return switch (this) {
      CefrLevel.a1 => l10n.levelA1,
      CefrLevel.a2 => l10n.levelA2,
      CefrLevel.b1 => l10n.levelB1,
      CefrLevel.b2 => l10n.levelB2,
      CefrLevel.c1 => l10n.levelC1,
      CefrLevel.c2 => l10n.levelC2,
    };
  }
}
