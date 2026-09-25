import 'package:design_system/design_system.dart';

import 'cefr_level.dart';

/// Each level's colour.
///
/// Defined once, beside the level itself, because two features paint with
/// it: the picker tints each level's card, and the round and its result are
/// drawn in the colour of the level being played — so choosing a level is
/// visibly carried into the game. The hues step round the wheel from cool
/// to warm as the levels get harder.
extension CefrLevelAccent on CefrLevel {
  AppAccent get accent => switch (this) {
    CefrLevel.a1 => AppAccent.teal,
    CefrLevel.a2 => AppAccent.blue,
    CefrLevel.b1 => AppAccent.indigo,
    CefrLevel.b2 => AppAccent.brand,
    CefrLevel.c1 => AppAccent.fuchsia,
    CefrLevel.c2 => AppAccent.orange,
  };
}
