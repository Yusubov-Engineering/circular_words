import 'package:rosco_api/rosco_api.dart';

import 'word_set.dart';

/// {@template word_bank_repository}
/// The feature's data contract for the words a round is played with.
///
/// Implementations throw `RoscoFailure` and nothing else.
/// {@endtemplate}
abstract interface class WordBankRepository {
  /// A complete A–Z set for [level], chosen at random from those authored.
  ///
  /// Throws `RoscoLevelUnavailable` when no bank ships for the level, and
  /// `RoscoWordBankMalformed` when one does but is not playable.
  Future<WordSet> randomSet(CefrLevel level);

  /// Every set authored for [level], for tests and tooling.
  Future<List<WordSet>> setsFor(CefrLevel level);
}
