import 'package:analytics_api/analytics_api.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:speech_api/speech_api.dart';

import '../domain/rosco_failure.dart';

// The round's analytics events. Parameters describe the game, never the
// player: no transcript, no typed answer — only which letter, which lap and
// how it went. What a player said is personal data; a count of it is not.

/// A round's words loaded and its clock started.
final class RoundStartedEvent extends AnalyticsEvent {
  RoundStartedEvent({required CefrLevel level, required String setId})
    : super('round_started', parameters: {'level': level.id, 'set_id': setId});
}

/// A round could not load its words — a bundled asset is missing or broken.
final class RoundLoadFailedEvent extends AnalyticsEvent {
  RoundLoadFailedEvent({
    required CefrLevel level,
    required RoscoFailure failure,
  }) : super(
         'round_load_failed',
         parameters: {
           'level': level.id,
           'failure': switch (failure) {
             RoscoLevelUnavailable() => 'unavailable',
             RoscoWordBankMalformed() => 'malformed',
             RoscoUnknownFailure() => 'unknown',
           },
         },
       );
}

/// A letter was answered correctly.
final class AnswerCorrectEvent extends AnalyticsEvent {
  AnswerCorrectEvent({
    required CefrLevel level,
    required String letter,
    required int lap,
  }) : super(
         'answer_correct',
         parameters: {'level': level.id, 'letter': letter, 'lap': lap},
       );
}

/// A letter was deferred to the next lap — by the player, or by its time
/// running out.
final class LetterPassedEvent extends AnalyticsEvent {
  LetterPassedEvent({
    required CefrLevel level,
    required String letter,
    required int lap,
    required bool timedOut,
  }) : super(
         'letter_passed',
         parameters: {
           'level': level.id,
           'letter': letter,
           'lap': lap,
           'timed_out': timedOut,
         },
       );
}

/// A round ended.
final class RoundFinishedEvent extends AnalyticsEvent {
  RoundFinishedEvent({
    required CefrLevel level,
    required LevelScore score,
    required int laps,
  }) : super(
         'round_finished',
         parameters: {
           'level': level.id,
           'score': score.correct,
           'seconds_left': score.secondsRemaining,
           'laps': laps,
         },
       );
}

/// The player opened the share sheet for a result.
final class ResultSharedEvent extends AnalyticsEvent {
  ResultSharedEvent({required CefrLevel level, required LevelScore score})
    : super(
        'result_shared',
        parameters: {'level': level.id, 'score': score.correct},
      );
}

/// The player played the same level again from its result.
final class RoundReplayedEvent extends AnalyticsEvent {
  RoundReplayedEvent({required CefrLevel level})
    : super('round_replayed', parameters: {'level': level.id});
}

/// Speech recognition is unavailable, so the round falls back to typing.
///
/// `midRound` separates a device that never had it from a microphone lost
/// part-way through — the second is the one that points at a bug.
final class SpeechUnavailableEvent extends AnalyticsEvent {
  SpeechUnavailableEvent({
    required SpeechUnavailableReason reason,
    required bool midRound,
  }) : super(
         'speech_unavailable',
         parameters: {'reason': reason.name, 'mid_round': midRound},
       );
}

/// The microphone stopped re-opening itself for a letter: every session in
/// a row closed as it opened.
final class MicGaveUpEvent extends AnalyticsEvent {
  MicGaveUpEvent({required int sessions})
    : super('mic_gave_up', parameters: {'sessions': sessions});
}
