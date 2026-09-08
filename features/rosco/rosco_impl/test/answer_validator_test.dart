import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_impl/src/domain/answer_validator.dart';
import 'package:rosco_impl/src/domain/word_entry.dart';

const validator = AnswerValidator();

WordEntry entry(
  String letter,
  String word, {
  List<String> synonyms = const [],
}) => WordEntry(
  letter: letter,
  word: word,
  definition: 'A clue that does not matter here.',
  synonyms: synonyms,
);

void main() {
  group('the answer as authored', () {
    final abundant = entry('A', 'abundant', synonyms: ['plentiful']);

    test('accepts the word itself, whatever the casing or spacing', () {
      expect(validator.accepts(entry: abundant, spoken: 'abundant'), isTrue);
      expect(validator.accepts(entry: abundant, spoken: '  Abundant '), isTrue);
      expect(validator.accepts(entry: abundant, spoken: 'ABUNDANT'), isTrue);
    });

    test('accepts an authored synonym even across letters', () {
      // The author of the clue decides what answers it. Removing "plentiful"
      // from the asset is how you make this a wrong answer — not a rule here.
      expect(validator.accepts(entry: abundant, spoken: 'plentiful'), isTrue);
    });

    test('rejects a different word', () {
      expect(validator.accepts(entry: abundant, spoken: 'abandoned'), isFalse);
      expect(validator.accepts(entry: abundant, spoken: 'ubuntu'), isFalse);
    });

    test('rejects nothing at all', () {
      expect(validator.accepts(entry: abundant, spoken: ''), isFalse);
      expect(validator.accepts(entry: abundant, spoken: '   '), isFalse);
      expect(validator.accepts(entry: abundant, spoken: '...'), isFalse);
    });
  });

  group('what a recogniser actually returns', () {
    final abundant = entry('A', 'abundant', synonyms: ['plentiful']);

    test('ignores a leading article', () {
      expect(
        validator.accepts(entry: abundant, spoken: 'the abundant'),
        isTrue,
      );
    });

    test('finds the answer inside a longer utterance', () {
      expect(validator.accepts(entry: abundant, spoken: 'um abundant'), isTrue);
      expect(
        validator.accepts(entry: abundant, spoken: 'i think abundant yes'),
        isTrue,
      );
    });

    // Measured on device: "abundant" came back as "albondant" among others.
    test('tolerates a misheard syllable in a long word', () {
      expect(validator.accepts(entry: abundant, spoken: 'albondant'), isTrue);
      expect(validator.accepts(entry: abundant, spoken: 'abundent'), isTrue);
    });

    test('hyphens and spacing never decide a match', () {
      final xray = entry('X', 'x-ray', synonyms: ['xray', 'ex ray']);

      expect(validator.accepts(entry: xray, spoken: 'x-ray'), isTrue);
      expect(validator.accepts(entry: xray, spoken: 'x ray'), isTrue);
      expect(validator.accepts(entry: xray, spoken: 'xray'), isTrue);
      // Authored, so accepted despite starting with the wrong letter.
      expect(validator.accepts(entry: xray, spoken: 'ex ray'), isTrue);
    });

    test('folds accents off a loan word', () {
      final cafe = entry('C', 'cafe');

      expect(validator.accepts(entry: cafe, spoken: 'café'), isTrue);
    });
  });

  group('inferred matches must still be words for this letter', () {
    // This is the guard that stops tolerance becoming "any similar word".
    test('a near miss under a different initial is rejected', () {
      final zone = entry('Z', 'zone');

      expect(validator.accepts(entry: zone, spoken: 'bone'), isFalse);
      expect(validator.accepts(entry: zone, spoken: 'tone'), isFalse);
      expect(validator.accepts(entry: zone, spoken: 'cone'), isFalse);
    });

    test('a homophone is accepted only under the right letter', () {
      final flower = entry('F', 'flower');

      expect(validator.accepts(entry: flower, spoken: 'flour'), isTrue);

      // Same pair, played from the other side: "flower" is not an F-answer's
      // business when the letter is L.
      final loud = entry('L', 'loud');
      expect(validator.accepts(entry: loud, spoken: 'flour'), isFalse);
    });
  });

  group('how much error a word can absorb', () {
    // A short word has no room: one edit turns it into a different word.
    test('a short word must be exact', () {
      final zoo = entry('Z', 'zoo');

      expect(validator.accepts(entry: zoo, spoken: 'zoo'), isTrue);
      expect(validator.accepts(entry: zoo, spoken: 'zoos'), isFalse);
      expect(validator.accepts(entry: zoo, spoken: 'zo'), isFalse);
    });

    test('a medium word absorbs one edit', () {
      final zebra = entry('Z', 'zebra');

      expect(validator.accepts(entry: zebra, spoken: 'zebrah'), isTrue);
      expect(validator.accepts(entry: zebra, spoken: 'zebrra'), isTrue);
      expect(validator.accepts(entry: zebra, spoken: 'zeeebra'), isFalse);
    });

    test('a long word absorbs two', () {
      final meticulous = entry('M', 'meticulous');

      expect(validator.accepts(entry: meticulous, spoken: 'meticulus'), isTrue);
      expect(validator.accepts(entry: meticulous, spoken: 'metikulus'), isTrue);
      expect(
        validator.accepts(entry: meticulous, spoken: 'metickyoolus'),
        isFalse,
      );
    });

    // Two eight-letter words one edit apart would both be accepted for each
    // other if the letter guard were not there; with it, this stays a
    // question of whether the tolerance is too generous, not of correctness.
    test('tolerance does not reach a genuinely different long word', () {
      final accountable = entry('A', 'accountable');

      expect(
        validator.accepts(entry: accountable, spoken: 'accountant'),
        isFalse,
      );
    });
  });
}
