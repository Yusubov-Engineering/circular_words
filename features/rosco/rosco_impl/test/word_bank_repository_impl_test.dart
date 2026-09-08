import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/data/word_bank_asset_data_source.dart';
import 'package:rosco_impl/src/data/word_bank_repository_impl.dart';
import 'package:rosco_impl/src/domain/rosco_failure.dart';
import 'package:rosco_impl/src/domain/word_set.dart';

/// Serves whatever string the test puts in, and mimics the real bundle by
/// throwing for anything absent.
final class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.contents);

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final value = contents[key];
    if (value == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

/// A complete, valid set — the baseline each malformed case departs from.
Map<String, dynamic> validSet(String id) => {
  'id': id,
  'entries': [
    for (final letter in WordSet.alphabet.split(''))
      {
        'letter': letter,
        'word': '$letter-word'.toLowerCase(),
        'definition': 'A definition for $letter.',
        'synonyms': <String>[],
      },
  ],
};

WordBankRepositoryImpl repositoryWith(
  Map<String, dynamic> document, {
  CefrLevel level = CefrLevel.a1,
  Random? random,
}) {
  final path = WordBankAssetDataSource.assetPathFor(level);

  return WordBankRepositoryImpl(
    dataSource: WordBankAssetDataSource(
      bundle: _FakeBundle({path: jsonEncode(document)}),
    ),
    random: random,
  );
}

void main() {
  group('setsFor', () {
    test('parses a complete document', () async {
      final repository = repositoryWith({
        'level': 'a1',
        'sets': [validSet('a1-1'), validSet('a1-2')],
      });

      final sets = await repository.setsFor(CefrLevel.a1);

      expect(sets, hasLength(2));
      expect(sets.first.id, 'a1-1');
      expect(sets.first.entries, hasLength(WordSet.letterCount));
      expect(sets.first.level, CefrLevel.a1);
    });

    // The asset's ordering should not matter; the game walks A-Z.
    test('orders entries by the alphabet regardless of asset order', () async {
      final shuffled = validSet('a1-1');
      shuffled['entries'] = (shuffled['entries']! as List<dynamic>).reversed
          .toList();

      final repository = repositoryWith({
        'sets': [shuffled],
      });
      final sets = await repository.setsFor(CefrLevel.a1);

      expect(sets.single.entries.map((e) => e.letter).join(), WordSet.alphabet);
    });

    test('an unauthored level reports as unavailable, not as an error', () {
      final repository = WordBankRepositoryImpl(
        dataSource: WordBankAssetDataSource(bundle: _FakeBundle(const {})),
      );

      expect(
        () => repository.setsFor(CefrLevel.c2),
        throwsA(
          isA<RoscoLevelUnavailable>().having(
            (f) => f.levelId,
            'levelId',
            'c2',
          ),
        ),
      );
    });

    // The alphabet is never relaxed: a short set is corrupt, not a short round.
    test('rejects a set with a missing letter', () {
      final incomplete = validSet('a1-1');
      (incomplete['entries']! as List<dynamic>).removeWhere(
        (entry) => (entry as Map<String, dynamic>)['letter'] == 'X',
      );

      final repository = repositoryWith({
        'sets': [incomplete],
      });

      expect(
        () => repository.setsFor(CefrLevel.a1),
        throwsA(
          isA<RoscoWordBankMalformed>().having(
            (f) => f.reason,
            'reason',
            contains('X'),
          ),
        ),
      );
    });

    test('rejects a duplicated letter', () {
      final duplicated = validSet('a1-1');
      (duplicated['entries']! as List<dynamic>).add({
        'letter': 'A',
        'word': 'another',
        'definition': 'A second entry for the same letter.',
      });

      final repository = repositoryWith({
        'sets': [duplicated],
      });

      expect(
        () => repository.setsFor(CefrLevel.a1),
        throwsA(isA<RoscoWordBankMalformed>()),
      );
    });

    test('rejects a word filed under the wrong letter', () {
      final wrong = validSet('a1-1');
      (wrong['entries']! as List<dynamic>)[0] = {
        'letter': 'A',
        'word': 'banana',
        'definition': 'A long yellow fruit.',
      };

      final repository = repositoryWith({
        'sets': [wrong],
      });

      expect(
        () => repository.setsFor(CefrLevel.a1),
        throwsA(isA<RoscoWordBankMalformed>()),
      );
    });

    test('rejects a document with no sets', () {
      final repository = repositoryWith({'level': 'a1', 'sets': <dynamic>[]});

      expect(
        () => repository.setsFor(CefrLevel.a1),
        throwsA(isA<RoscoWordBankMalformed>()),
      );
    });

    test('rejects a document that is not JSON at all', () {
      final repository = WordBankRepositoryImpl(
        dataSource: WordBankAssetDataSource(
          bundle: _FakeBundle({
            WordBankAssetDataSource.assetPathFor(CefrLevel.a1): 'not json',
          }),
        ),
      );

      expect(
        () => repository.setsFor(CefrLevel.a1),
        throwsA(isA<RoscoFailure>()),
      );
    });

    // Losing one synonym costs an accepted answer; rejecting the entry would
    // cost the player the whole letter.
    test('a malformed synonyms field degrades to no synonyms', () async {
      final odd = validSet('a1-1');
      (odd['entries']! as List<dynamic>)[0] = {
        'letter': 'A',
        'word': 'apple',
        'definition': 'A round red fruit.',
        'synonyms': 'not a list',
      };

      final repository = repositoryWith({
        'sets': [odd],
      });
      final sets = await repository.setsFor(CefrLevel.a1);

      expect(sets.single.entries.first.synonyms, isEmpty);
      expect(sets.single.entries.first.word, 'apple');
    });
  });

  group('randomSet', () {
    test('returns one of the authored sets', () async {
      final repository = repositoryWith({
        'sets': [validSet('a1-1'), validSet('a1-2')],
      }, random: Random(1));

      final set = await repository.randomSet(CefrLevel.a1);

      expect(['a1-1', 'a1-2'], contains(set.id));
      expect(set.entries, hasLength(WordSet.letterCount));
    });

    test('is deterministic when given a seeded Random', () async {
      Future<String> pick() async {
        final repository = repositoryWith({
          'sets': [validSet('a1-1'), validSet('a1-2'), validSet('a1-3')],
        }, random: Random(7));
        return (await repository.randomSet(CefrLevel.a1)).id;
      }

      expect(await pick(), await pick());
    });
  });

  group('WordSet', () {
    test('finds an entry by letter, case-insensitively', () async {
      final repository = repositoryWith({
        'sets': [validSet('a1-1')],
      });
      final set = await repository.randomSet(CefrLevel.a1);

      expect(set.entryFor('q')?.letter, 'Q');
      expect(set.entryFor('Q')?.letter, 'Q');
    });

    test('accepted answers include the word and its synonyms', () async {
      final withSynonyms = validSet('a1-1');
      (withSynonyms['entries']! as List<dynamic>)[0] = {
        'letter': 'A',
        'word': 'abundant',
        'definition': 'More than enough of something.',
        'synonyms': ['plentiful', ' ample '],
      };

      final repository = repositoryWith({
        'sets': [withSynonyms],
      });
      final set = await repository.randomSet(CefrLevel.a1);

      expect(set.entryFor('A')?.acceptedAnswers, [
        'abundant',
        'plentiful',
        'ample',
      ]);
    });
  });
}
