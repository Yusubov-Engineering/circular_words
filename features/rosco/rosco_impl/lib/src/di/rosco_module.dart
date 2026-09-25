import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:flutter/services.dart';
import 'package:rosco_api/rosco_api.dart';

import '../data/rosco_scoreboard_impl.dart';
import '../data/word_bank_asset_data_source.dart';
import '../data/word_bank_repository_impl.dart';
import '../domain/word_bank_repository.dart';
import '../share/result_sharer.dart';
import 'rosco_api_impl.dart';

/// {@template rosco_module}
/// Registers this feature's public facade and the pieces behind it.
///
/// Registered under types declared in `lib/src/` where they are private, and
/// under `rosco_api` types where other modules need them: shared container,
/// private contracts.
///
/// Must come after `StorageModule`, which the scoreboard resolves.
/// {@endtemplate}
final class RoscoModule implements DependencyModule {
  @override
  String get name => 'Rosco';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container
      ..registerLazySingleton<WordBankRepository>(
        (_) => WordBankRepositoryImpl(
          dataSource: WordBankAssetDataSource(bundle: rootBundle),
        ),
      )
      ..registerLazySingleton<RoscoScoreboard>(
        (locator) => RoscoScoreboardImpl(storage: locator()),
      )
      ..registerLazySingleton<ResultSharer>(
        (_) => const SharePlusResultSharer(),
      )
      ..registerLazySingleton<RoscoApi>(
        (locator) => RoscoApiImpl(scoreboard: locator()),
      );
  }
}
