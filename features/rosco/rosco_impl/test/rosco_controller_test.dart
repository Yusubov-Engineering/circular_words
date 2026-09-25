import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/domain/letter_slot.dart';
import 'package:rosco_impl/src/domain/rosco_failure.dart';
import 'package:rosco_impl/src/domain/word_bank_repository.dart';
import 'package:rosco_impl/src/domain/word_entry.dart';
import 'package:rosco_impl/src/domain/word_set.dart';
import 'package:rosco_impl/src/rosco/rosco_controller.dart';

/// A full A-Z set whose answers are trivially predictable, so a test can say
/// "answer C correctly" without caring what a C word is.
WordSet fakeSet({CefrLevel level = CefrLevel.a1, String id = 'fake-1'}) =>
    WordSet(
      id: id,
      level: level,
      entries: [
        for (final letter in WordSet.alphabet.split(''))
          WordEntry(
            letter: letter,
            word: '${letter.toLowerCase()}word',
            definition: 'The clue for $letter.',
          ),
      ],
    );

/// The answer the fake set expects for [letter].
String answerFor(String letter) => '${letter.toLowerCase()}word';

final class FakeRepository implements WordBankRepository {
  FakeRepository({this.set, this.failure});

  final WordSet? set;
  final RoscoFailure? failure;

  @override
  Future<WordSet> randomSet(CefrLevel level) async {
    final thrown = failure;
    if (thrown != null) throw thrown;
    return set ?? fakeSet(level: level);
  }

  @override
  Future<List<WordSet>> setsFor(CefrLevel level) async => [
    await randomSet(level),
  ];
}

/// Drives the round's clock by hand: one call, one second.
final class ManualClock {
  final _controller = StreamController<void>.broadcast();

  Stream<void> source() => _controller.stream;

  Future<void> tick([int seconds = 1]) async {
    for (var i = 0; i < seconds; i++) {
      _controller.add(null);
      // Let the dispatched event be handled before the next beat.
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> close() => _controller.close();
}

/// A started round, plus the effects it has emitted.
final class Round {
  Round(this.controller, this.clock, this.effects, this._subscription);

  final RoscoController controller;
  final ManualClock clock;
  final List<RoscoEffect> effects;
  final StreamSubscription<RoscoEffect> _subscription;

  RoscoState get state => controller.state;

  Future<void> answer(String text) async {
    await controller.onEvent(RoscoAnswered(answer: text));
    await Future<void>.delayed(Duration.zero);
  }

  /// What the microphone dispatches: a best guess, its alternates, and
  /// whether the player has stopped speaking.
  Future<void> heard(
    String transcript, {
    List<String> alternates = const [],
    bool tentative = false,
  }) async {
    await controller.onEvent(
      RoscoAnswered(
        answer: transcript,
        alternates: alternates,
        tentative: tentative,
      ),
    );
    await Future<void>.delayed(Duration.zero);
  }

  /// Answers the letter currently being played, correctly.
  Future<void> answerCurrent() => answer(answerFor(state.current!.letter));

  Future<void> pass() async {
    await controller.onEvent(const RoscoPassed());
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await clock.close();
    controller.dispose();
  }
}

Future<Round> startRound({
  WordSet? set,
  RoscoFailure? failure,
  CefrLevel level = CefrLevel.a1,
}) async {
  final clock = ManualClock();
  final controller = RoscoController(
    level: level,
    repository: FakeRepository(set: set, failure: failure),
    tickSource: clock.source,
  );

  final effects = <RoscoEffect>[];
  // Cancelled in Round.dispose, which every test calls.
  // ignore: cancel_subscriptions
  final subscription = controller.effects.listen(effects.add);

  await controller.onInit();
  await Future<void>.delayed(Duration.zero);

  return Round(controller, clock, effects, subscription);
}

void main() {
  group('starting a round', () {
    test('loads a set and activates A', () async {
      final round = await startRound();

      expect(round.state.isLoading, isFalse);
      expect(round.state.slots, hasLength(WordSet.letterCount));
      expect(round.state.current?.letter, 'A');
      expect(round.state.current?.status, LetterStatus.active);
      expect(round.state.remainingPool, kPoolSeconds);
      expect(round.state.lap, 1);

      await round.dispose();
    });

    test('a failure to load is a state, not a crash', () async {
      final round = await startRound(
        failure: const RoscoLevelUnavailable(levelId: 'c2'),
      );

      expect(round.state.failure, isA<RoscoLevelUnavailable>());
      expect(round.state.isLoading, isFalse);
      expect(round.state.slots, isEmpty);

      await round.dispose();
    });
  });

  group('the pool is the only clock', () {
    test('the letter countdown is derived from the pool', () async {
      final round = await startRound();

      expect(round.state.letterRemaining, kLetterCapSeconds);

      await round.clock.tick(3);

      expect(round.state.remainingPool, kPoolSeconds - 3);
      expect(round.state.letterRemaining, kLetterCapSeconds - 3);

      await round.dispose();
    });

    // The failure this guards against is specific: with two independent
    // clocks, the last letter is offered ten seconds the pool cannot pay for.
    test('the letter never offers more time than the pool holds', () async {
      final round = await startRound();

      // Burn the pool down to less than one letter's worth by passing.
      await round.clock.tick(kPoolSeconds - 4);

      expect(round.state.remainingPool, 4);
      expect(round.state.letterRemaining, lessThanOrEqualTo(4));

      await round.dispose();
    });

    test('answering fast banks the rest of the letter for later', () async {
      final round = await startRound();

      await round.clock.tick(2);
      await round.answerCurrent();

      // Two seconds spent, not ten: the other eight are still in the pool.
      expect(round.state.remainingPool, kPoolSeconds - 2);
      expect(round.state.spentOnCurrentLetter, 0);
      expect(round.state.letterRemaining, kLetterCapSeconds);

      await round.dispose();
    });
  });

  group('answering', () {
    test('an accepted answer resolves the letter and advances', () async {
      final round = await startRound();

      await round.answerCurrent();

      expect(round.state.slots.first.status, LetterStatus.correct);
      expect(round.state.current?.letter, 'B');
      expect(round.effects.whereType<RoscoAccepted>(), hasLength(1));

      await round.dispose();
    });

    // The rule most likely to be broken by accident: the obvious way to
    // "handle a wrong answer" advances the letter, and that is exactly what
    // must not happen.
    test('a rejected answer leaves the letter active', () async {
      final round = await startRound();

      await round.answer('definitely not it');

      expect(round.state.current?.letter, 'A');
      expect(round.state.current?.status, LetterStatus.active);
      expect(round.state.lastRejected, 'definitely not it');
      expect(round.effects.whereType<RoscoRejected>(), hasLength(1));

      await round.dispose();
    });

    test('the player may retry until the cap expires', () async {
      final round = await startRound();

      await round.answer('wrong');
      await round.clock.tick(2);
      await round.answer('also wrong');
      await round.clock.tick(2);
      await round.answerCurrent();

      expect(round.state.slots.first.status, LetterStatus.correct);
      expect(round.effects.whereType<RoscoRejected>(), hasLength(2));
      expect(round.effects.whereType<RoscoAccepted>(), hasLength(1));

      await round.dispose();
    });

    test('a wrong answer costs time, and the time is real', () async {
      final round = await startRound();

      await round.clock.tick(4);
      await round.answer('wrong');

      // The clock did not rewind on rejection.
      expect(round.state.remainingPool, kPoolSeconds - 4);
      expect(round.state.letterRemaining, kLetterCapSeconds - 4);

      await round.dispose();
    });

    // Running out of time is a pass the player did not ask for. It was once
    // final, which ended a round with time left for anyone who never pressed
    // Pass: every letter was decided on the first lap.
    test('the cap sends a letter round again, never out', () async {
      final round = await startRound();

      await round.clock.tick(kLetterCapSeconds);

      expect(round.state.slots.first.status, LetterStatus.passed);
      expect(round.state.current?.letter, 'B');
      expect(round.effects, contains(isA<RoscoTimedOut>()));

      await round.dispose();
    });

    test('a timed-out letter comes back on the next lap', () async {
      final round = await startRound();

      await round.clock.tick(kLetterCapSeconds); // A runs out
      for (var i = 1; i < WordSet.letterCount; i++) {
        await round.answerCurrent(); // B..Z answered
      }

      expect(round.state.isOver, isFalse);
      expect(round.state.lap, 2);
      expect(round.state.current?.letter, 'A');

      await round.dispose();
    });

    test('whatever is unanswered at the end is marked missed', () async {
      final round = await startRound();

      await round.answerCurrent(); // A correct
      await round.clock.tick(kPoolSeconds); // the pool runs dry

      expect(round.state.isOver, isTrue);
      expect(round.state.slots.first.status, LetterStatus.correct);
      expect(
        round.state.slots.skip(1).map((slot) => slot.status),
        everyElement(LetterStatus.wrong),
      );
      expect(round.state.correctCount, 1);

      await round.dispose();
    });
  });

  group('passing and laps', () {
    test('a passed letter is deferred, not resolved', () async {
      final round = await startRound();

      await round.pass();

      expect(round.state.slots.first.status, LetterStatus.passed);
      expect(round.state.slots.first.isTerminal, isFalse);
      expect(round.state.current?.letter, 'B');
      expect(round.state.lap, 1);

      await round.dispose();
    });

    test('the circle comes back round to a passed letter', () async {
      final round = await startRound();

      await round.pass(); // A deferred
      for (var i = 0; i < WordSet.letterCount - 1; i++) {
        await round.answerCurrent(); // B..Z answered
      }

      // Wrapping past Z starts lap two, and A is what is left.
      expect(round.state.lap, 2);
      expect(round.state.current?.letter, 'A');
      expect(round.state.current?.status, LetterStatus.active);
      expect(round.state.correctCount, WordSet.letterCount - 1);

      await round.dispose();
    });

    // Passing the only letter left is a real move, and the rules say what it
    // does: `passed` is not terminal, so there is still something unresolved,
    // so the round does not end. The circle simply comes straight back to it.
    test(
      'passing the last unresolved letter brings it straight back',
      () async {
        final round = await startRound();

        await round.pass();
        for (var i = 0; i < WordSet.letterCount - 1; i++) {
          await round.answerCurrent();
        }
        expect(round.state.current?.letter, 'A');
        final lapBefore = round.state.lap;

        await round.pass();

        expect(round.state.isOver, isFalse);
        expect(round.state.current?.letter, 'A');
        expect(round.state.current?.status, LetterStatus.active);
        expect(round.state.lap, lapBefore + 1);

        await round.dispose();
      },
    );

    // ...and it costs nothing extra, because only the clock drains the pool.
    // The round still ends, on time rather than on moves.
    test('pass-spamming the last letter still runs the pool down', () async {
      final round = await startRound();

      await round.pass();
      for (var i = 0; i < WordSet.letterCount - 1; i++) {
        await round.answerCurrent();
      }

      for (var i = 0; i < 5; i++) {
        await round.pass();
      }
      expect(round.state.isOver, isFalse);
      expect(round.state.remainingPool, kPoolSeconds);

      await round.clock.tick(kPoolSeconds);

      expect(round.state.isOver, isTrue);
      expect(round.state.correctCount, WordSet.letterCount - 1);

      await round.dispose();
    });
  });

  group('ending a round', () {
    test('ends when every letter is terminal', () async {
      final round = await startRound();

      for (var i = 0; i < WordSet.letterCount; i++) {
        await round.answerCurrent();
      }

      expect(round.state.isOver, isTrue);
      expect(round.state.correctCount, WordSet.letterCount);

      final finished = round.effects.whereType<RoscoFinished>().single;
      expect(finished.score.correct, WordSet.letterCount);
      expect(finished.score.total, WordSet.letterCount);

      await round.dispose();
    });

    test('ends when the pool runs out', () async {
      final round = await startRound();

      await round.clock.tick(kPoolSeconds);

      expect(round.state.isOver, isTrue);
      expect(round.state.remainingPool, 0);
      expect(round.effects.whereType<RoscoFinished>(), hasLength(1));

      await round.dispose();
    });

    // "Run the pool down": a lap with nothing answered must not end the round.
    test('a whole lap of passes does not end the round', () async {
      final round = await startRound();

      for (var i = 0; i < WordSet.letterCount; i++) {
        await round.pass();
      }

      expect(round.state.isOver, isFalse);
      expect(round.state.lap, 2);
      expect(round.state.remainingPool, kPoolSeconds);
      expect(round.state.unresolvedCount, WordSet.letterCount);

      await round.dispose();
    });

    test('the score carries the time left, for ranking', () async {
      final round = await startRound();

      await round.clock.tick(5);
      for (var i = 0; i < WordSet.letterCount; i++) {
        await round.answerCurrent();
      }

      final finished = round.effects.whereType<RoscoFinished>().single;
      expect(finished.score.secondsRemaining, kPoolSeconds - 5);

      await round.dispose();
    });

    test('the round finishes exactly once', () async {
      final round = await startRound();

      for (var i = 0; i < WordSet.letterCount; i++) {
        await round.answerCurrent();
      }
      // Further input after the end must not re-finish or re-score.
      await round.answer('anything');
      await round.pass();
      await round.clock.tick(5);

      expect(round.effects.whereType<RoscoFinished>(), hasLength(1));

      await round.dispose();
    });

    test('the clock stops when the round ends', () async {
      final round = await startRound();

      for (var i = 0; i < WordSet.letterCount; i++) {
        await round.answerCurrent();
      }
      final poolAtEnd = round.state.remainingPool;

      await round.clock.tick(5);

      expect(round.state.remainingPool, poolAtEnd);

      await round.dispose();
    });
  });

  group('a played-out round', () {
    // The shape a real game takes: some right, some passed, some out of time
    // — and during play the last two look the same, because both come back.
    test('mixes correct, passed and timed-out letters', () async {
      final round = await startRound();

      await round.answerCurrent(); // A correct
      await round.pass(); // B deferred
      await round.clock.tick(kLetterCapSeconds); // C times out
      await round.answerCurrent(); // D correct

      final byLetter = {
        for (final slot in round.state.slots) slot.letter: slot.status,
      };

      expect(byLetter['A'], LetterStatus.correct);
      expect(byLetter['B'], LetterStatus.passed);
      expect(byLetter['C'], LetterStatus.passed);
      expect(byLetter['D'], LetterStatus.correct);
      expect(round.state.current?.letter, 'E');
      expect(round.state.correctCount, 2);
      expect(round.state.isOver, isFalse);

      await round.dispose();
    });
  });

  group('answering by voice', () {
    test('an alternate can be the right answer', () async {
      final round = await startRound();

      // The top-ranked transcript is regularly not the best one — on device,
      // "albondant" outranked "abundant".
      await round.heard('a bun dance', alternates: ['nonsense', 'aword']);

      expect(round.state.slots.first.status, LetterStatus.correct);
      expect(round.effects, contains(isA<RoscoAccepted>()));
      await round.dispose();
    });

    test('a tentative miss is neither shown nor felt', () async {
      final round = await startRound();

      await round.heard('a bun', tentative: true);

      // The player is mid-word. Nothing has been got wrong yet.
      expect(round.state.lastRejected, isNull);
      expect(round.effects, isEmpty);
      expect(round.state.current?.letter, 'A');
      expect(round.state.current?.status, LetterStatus.active);
      await round.dispose();
    });

    test('a tentative hit is scored immediately', () async {
      final round = await startRound();

      // The measured gap between the partial that already holds the answer
      // and the final that repeats it is about five seconds — half the
      // letter. Waiting for the final would make a second lap impossible.
      await round.heard('aword', tentative: true);

      expect(round.state.slots.first.status, LetterStatus.correct);
      expect(round.state.current?.letter, 'B');
      await round.dispose();
    });

    test('a settled miss is shown and felt', () async {
      final round = await startRound();

      await round.heard('a bun dance', alternates: ['a bundle']);

      expect(round.state.lastRejected, 'a bun dance');
      expect(round.effects, contains(isA<RoscoRejected>()));
      expect(round.state.current?.status, LetterStatus.active);
      await round.dispose();
    });

    test('the rejected line shows the best guess, not an alternate', () async {
      final round = await startRound();

      await round.heard('a bun dance', alternates: ['Ubuntu', 'album dumped']);

      // "Ubuntu" is noise from the recogniser. Showing it back would read as
      // the game mishearing rather than the player missing.
      expect(round.state.lastRejected, 'a bun dance');
      await round.dispose();
    });
  });
}
