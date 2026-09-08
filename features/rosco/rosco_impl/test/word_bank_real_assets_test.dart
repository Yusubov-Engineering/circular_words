import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/data/word_bank_asset_data_source.dart';
import 'package:rosco_impl/src/data/word_bank_repository_impl.dart';
import 'package:rosco_impl/src/domain/rosco_failure.dart';
import 'package:rosco_impl/src/domain/word_set.dart';

/// The shipped assets, read through the *real* bundle at the *production*
/// path — the `packages/rosco_impl/...` form the app resolves.
///
/// The fake-bundle tests prove the parsing rules; this proves the wiring. A
/// wrong asset path parses perfectly in every unit test and then fails only
/// on a device, which is exactly the class of bug worth a test of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = WordBankRepositoryImpl(
    dataSource: WordBankAssetDataSource(bundle: rootBundle),
  );

  test('the production asset path is the packages/ form', () {
    expect(
      WordBankAssetDataSource.assetPathFor(CefrLevel.b1),
      'packages/rosco_impl/assets/words/b1.json',
    );
  });

  for (final level in CefrLevel.values) {
    test('${level.label} loads and every set is playable', () async {
      final sets = await repository.setsFor(level);

      expect(sets, isNotEmpty);
      for (final set in sets) {
        expect(set.level, level);
        expect(set.entries, hasLength(WordSet.letterCount));
        expect(set.entries.map((e) => e.letter).join(), WordSet.alphabet);
        expect(set.entryFor('X'), isNotNull);
        expect(set.entryFor('Z'), isNotNull);
      }
    });
  }

  test('a random set for an authored level is always complete', () async {
    final set = await repository.randomSet(CefrLevel.a1);

    expect(set.entries, hasLength(WordSet.letterCount));
  });

  // Every level ships a bank now, so the unavailable path is no longer
  // reachable through a real level. It is still what a missing asset must
  // produce, so it stays covered against an empty bundle rather than being
  // deleted along with the last unauthored level.
  test('a missing asset still reports as unavailable, not as an error', () {
    final empty = WordBankRepositoryImpl(
      dataSource: WordBankAssetDataSource(bundle: _EmptyBundle()),
    );

    expect(
      () => empty.setsFor(CefrLevel.c2),
      throwsA(isA<RoscoLevelUnavailable>()),
    );
  });
}

/// A bundle with nothing in it — a level whose asset was never added, or was
/// dropped from `pubspec.yaml`.
final class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Unable to load asset: $key');
}
