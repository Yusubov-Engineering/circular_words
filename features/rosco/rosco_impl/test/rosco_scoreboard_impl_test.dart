import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/data/rosco_scoreboard_impl.dart';
import 'package:storage_api/storage_api.dart';

/// In-memory storage that can also be made to fail, so the degradation paths
/// are exercised rather than assumed.
final class _FakeStorage implements StandardStorageApi {
  final Map<String, Map<String, dynamic>> values = {};
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    if (failReads) throw StateError('storage unavailable');
    return values[key];
  }

  @override
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> json,
  }) async {
    if (failWrites) throw StateError('storage unavailable');
    values[key] = json;
  }

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<bool?> readBool({required String key}) async => null;

  @override
  Future<String?> readString({required String key}) async => null;

  @override
  Future<void> writeBool({required String key, required bool value}) async {}

  @override
  Future<void> writeString({
    required String key,
    required String value,
  }) async {}
}

void main() {
  late _FakeStorage storage;
  late RoscoScoreboard scoreboard;

  setUp(() {
    storage = _FakeStorage();
    scoreboard = RoscoScoreboardImpl(storage: storage);
  });

  test('an unplayed level has no score', () async {
    expect(await scoreboard.best(CefrLevel.b1), isNull);
    expect(await scoreboard.all(), isEmpty);
  });

  test('records a first score and reads it back', () async {
    const score = LevelScore(correct: 12, total: 26, secondsRemaining: 30);

    expect(await scoreboard.record(CefrLevel.b1, score), isTrue);
    expect(await scoreboard.best(CefrLevel.b1), score);
  });

  test('keeps the better score and reports that it did not replace', () async {
    const first = LevelScore(correct: 20, total: 26, secondsRemaining: 10);
    const worse = LevelScore(correct: 4, total: 26, secondsRemaining: 200);

    await scoreboard.record(CefrLevel.c1, first);

    expect(await scoreboard.record(CefrLevel.c1, worse), isFalse);
    expect(await scoreboard.best(CefrLevel.c1), first);
  });

  // Per-level keys exist so one corrupt entry cannot take the picker down.
  test('levels are stored independently', () async {
    const a1 = LevelScore(correct: 26, total: 26, secondsRemaining: 100);
    const c2 = LevelScore(correct: 3, total: 26, secondsRemaining: 5);

    await scoreboard.record(CefrLevel.a1, a1);
    await scoreboard.record(CefrLevel.c2, c2);

    expect(await scoreboard.all(), {CefrLevel.a1: a1, CefrLevel.c2: c2});
  });

  test('corrupt stored data for one level reads as unplayed', () async {
    await scoreboard.record(
      CefrLevel.a2,
      const LevelScore(correct: 9, total: 26, secondsRemaining: 8),
    );
    storage.values[RoscoScoreboardImpl.keyFor(CefrLevel.b1)] = {
      'correct': 'nonsense',
    };

    expect(await scoreboard.best(CefrLevel.b1), isNull);
    // The healthy level is untouched.
    expect(await scoreboard.best(CefrLevel.a2), isNotNull);
  });

  test('unreadable storage reads as unplayed rather than throwing', () async {
    storage.failReads = true;

    expect(await scoreboard.best(CefrLevel.b2), isNull);
    expect(await scoreboard.all(), isEmpty);
  });

  // Losing a score is bad; losing the round that earned it would be worse.
  test('a failed write reports false instead of throwing', () async {
    storage.failWrites = true;

    expect(
      await scoreboard.record(
        CefrLevel.b2,
        const LevelScore(correct: 7, total: 26, secondsRemaining: 3),
      ),
      isFalse,
    );
  });
}
