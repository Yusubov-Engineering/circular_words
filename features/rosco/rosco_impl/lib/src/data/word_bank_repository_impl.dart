import 'dart:math';

import 'package:rosco_api/rosco_api.dart';

import '../domain/rosco_failure.dart';
import '../domain/word_bank_repository.dart';
import '../domain/word_entry.dart';
import '../domain/word_set.dart';
import 'word_bank_asset_data_source.dart';
import 'word_entry_dto.dart';

/// {@template word_bank_repository_impl}
/// Turns bundled assets into playable sets.
///
/// This is the single place exceptions become [RoscoFailure]s: nothing above
/// it sees a `FlutterError`, a `FormatException` or a `TypeError`.
/// {@endtemplate}
final class WordBankRepositoryImpl({
  required final WordBankAssetDataSource _dataSource,
  final Random? _random,
}) implements WordBankRepository {
  @override
  Future<WordSet> randomSet(CefrLevel level) async {
    final sets = await setsFor(level);

    // `setsFor` rejects a document with no usable sets, so this is only
    // reachable if that guard is ever removed.
    if (sets.isEmpty) {
      throw RoscoWordBankMalformed(
        levelId: level.id,
        reason: 'no playable sets',
      );
    }

    return sets[(_random ?? Random()).nextInt(sets.length)];
  }

  @override
  Future<List<WordSet>> setsFor(CefrLevel level) async {
    final Map<String, dynamic> document;

    try {
      document = await _dataSource.load(level);
    } on WordBankAssetException {
      // An unreadable asset means the level is not authored yet — a real
      // state, since the picker offers all six levels from the start.
      throw RoscoLevelUnavailable(levelId: level.id);
    } on FormatException catch (error) {
      throw RoscoWordBankMalformed(levelId: level.id, reason: '$error');
    } on RoscoFailure {
      rethrow;
    } on Object catch (error) {
      throw RoscoUnknownFailure(cause: error);
    }

    final rawSets = document['sets'];
    if (rawSets is! List || rawSets.isEmpty) {
      throw RoscoWordBankMalformed(
        levelId: level.id,
        reason: 'missing or empty "sets"',
      );
    }

    return [
      for (var index = 0; index < rawSets.length; index++)
        _parseSet(level, rawSets[index], index),
    ];
  }

  WordSet _parseSet(CefrLevel level, Object? raw, int index) {
    if (raw is! Map<String, dynamic>) {
      throw RoscoWordBankMalformed(
        levelId: level.id,
        reason: 'set $index is not an object',
      );
    }

    final id = raw['id'] is String && (raw['id'] as String).trim().isNotEmpty
        ? (raw['id'] as String).trim()
        : '${level.id}-$index';

    final rawEntries = raw['entries'];
    if (rawEntries is! List) {
      throw RoscoWordBankMalformed(
        levelId: level.id,
        reason: 'set $id has no "entries" list',
      );
    }

    final byLetter = <String, WordEntry>{};

    for (final rawEntry in rawEntries) {
      final entry = WordEntryDto.fromJson(rawEntry);
      if (entry == null) {
        throw RoscoWordBankMalformed(
          levelId: level.id,
          reason: 'set $id contains an unusable entry',
        );
      }
      if (byLetter.containsKey(entry.letter)) {
        throw RoscoWordBankMalformed(
          levelId: level.id,
          reason: 'set $id has two entries for ${entry.letter}',
        );
      }
      byLetter[entry.letter] = entry;
    }

    // The alphabet is never relaxed, so a short set is corrupt rather than a
    // shorter round. Ordering by the alphabet here also means the asset's own
    // ordering does not matter.
    final missing = [
      for (final letter in WordSet.alphabet.split(''))
        if (!byLetter.containsKey(letter)) letter,
    ];

    if (missing.isNotEmpty) {
      throw RoscoWordBankMalformed(
        levelId: level.id,
        reason: 'set $id is missing ${missing.join(", ")}',
      );
    }

    return WordSet(
      id: id,
      level: level,
      entries: [
        for (final letter in WordSet.alphabet.split('')) byLetter[letter]!,
      ],
    );
  }
}
