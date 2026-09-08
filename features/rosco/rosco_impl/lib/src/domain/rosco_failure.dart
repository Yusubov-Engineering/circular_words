/// Everything that can go wrong loading a round's words.
///
/// Sealed, so a new failure kind fails to compile at every point that handles
/// one rather than quietly becoming "something went wrong". The repository
/// throws these and nothing else — no asset exception, no format exception,
/// reaches a controller.
sealed class RoscoFailure implements Exception {
  const RoscoFailure();
}

/// No word bank ships for this level yet.
///
/// A real state, not a bug: levels are authored over time, and the picker
/// offers all six from the start.
final class const RoscoLevelUnavailable({required final String levelId})
    extends RoscoFailure {
  @override
  String toString() => 'RoscoLevelUnavailable($levelId)';
}

/// The asset exists but does not describe a playable round.
///
/// Carries [reason] for the log, never for the player — a controller has no
/// `BuildContext` and cannot localize, so the sentence shown is chosen at the
/// widget layer.
final class const RoscoWordBankMalformed({
  required final String levelId,
  required final String reason,
}) extends RoscoFailure {
  @override
  String toString() => 'RoscoWordBankMalformed($levelId: $reason)';
}

/// Anything the layers below failed to explain.
final class const RoscoUnknownFailure({final Object? cause})
    extends RoscoFailure {
  @override
  String toString() => 'RoscoUnknownFailure($cause)';
}
