import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/domain/word_set.dart';

/// Which levels ship a word bank today.
///
/// Now every level. Kept as an explicit set rather than `CefrLevel.values` so
/// that dropping a level is a deliberate edit, and so the loop below still
/// reads as "these are the shipped ones".
const _authoredLevels = CefrLevel.values;

void main() {
  group('shipped word banks', () {
    for (final level in _authoredLevels) {
      group(level.label, () {
        late List<dynamic> sets;

        setUpAll(() {
          final file = File('assets/words/${level.id}.json');
          expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

          final document =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          sets = document['sets'] as List<dynamic>;
        });

        // Five is the floor, not a target: with two, a player who replays a
        // level sees the same round every other time.
        test('ships at least five sets, so replays rarely repeat', () {
          expect(sets.length, greaterThanOrEqualTo(5));
        });

        test('no word is used twice across the sets of a level', () {
          final words = [
            for (final set in sets)
              for (final entry
                  in (set as Map<String, dynamic>)['entries'] as List<dynamic>)
                ((entry as Map<String, dynamic>)['word'] as String)
                    .toLowerCase(),
          ];
          final repeated = {
            for (final word in words)
              if (words.where((other) => other == word).length > 1) word,
          };

          expect(repeated, isEmpty, reason: 'repeated: $repeated');
        });

        // The rules never relax the alphabet, not even for X and Z, so a set
        // with a hole is unplayable rather than short. This test is the only
        // thing standing between a typo and a broken level.
        test('every set covers all 26 letters exactly once', () {
          for (final raw in sets) {
            final set = raw as Map<String, dynamic>;
            final entries = set['entries'] as List<dynamic>;
            final letters = [
              for (final entry in entries)
                (entry as Map<String, dynamic>)['letter'] as String,
            ];

            expect(
              letters.toSet().length,
              WordSet.letterCount,
              reason: '${set['id']} does not have 26 distinct letters',
            );
            expect(
              letters.toSet(),
              WordSet.alphabet.split('').toSet(),
              reason: '${set['id']} is not a complete A-Z',
            );
          }
        });

        test('every word starts with its own letter', () {
          for (final raw in sets) {
            final set = raw as Map<String, dynamic>;
            for (final rawEntry in set['entries'] as List<dynamic>) {
              final entry = rawEntry as Map<String, dynamic>;
              final word = entry['word'] as String;
              final letter = entry['letter'] as String;

              expect(
                word[0].toUpperCase(),
                letter.toUpperCase(),
                reason: '"$word" is filed under $letter in ${set['id']}',
              );
            }
          }
        });

        // A clue that contains its own answer is not a clue.
        test('no definition gives away its answer', () {
          for (final raw in sets) {
            final set = raw as Map<String, dynamic>;
            for (final rawEntry in set['entries'] as List<dynamic>) {
              final entry = rawEntry as Map<String, dynamic>;
              final word = (entry['word'] as String).toLowerCase();
              final definition = (entry['definition'] as String).toLowerCase();

              expect(
                definition.contains(word),
                isFalse,
                reason: '${set['id']}: "$word" appears in its own definition',
              );
            }
          }
        });

        test('every definition is a non-empty sentence', () {
          for (final raw in sets) {
            final set = raw as Map<String, dynamic>;
            for (final rawEntry in set['entries'] as List<dynamic>) {
              final entry = rawEntry as Map<String, dynamic>;
              final definition = (entry['definition'] as String).trim();

              expect(definition, isNotEmpty);
              expect(definition.length, greaterThan(10));
            }
          }
        });
      });
    }
  });
}
