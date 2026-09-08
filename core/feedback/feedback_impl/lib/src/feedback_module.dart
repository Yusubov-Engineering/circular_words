import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:feedback_api/feedback_api.dart';
import 'package:storage_api/storage_api.dart';

import 'game_feedback_impl.dart';

/// {@template feedback_module}
/// Registers the game's sound and haptics.
///
/// Lazily and as a singleton: the players hold decoded audio and a platform
/// channel each, and a second set would be both wasteful and audible.
///
/// Must come after `StorageModule`, which the muted preference is read from.
/// {@endtemplate}
final class FeedbackModule implements DependencyModule {
  @override
  String get name => 'Feedback';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerLazySingleton<GameFeedbackApi>(
      (locator) => GameFeedbackImpl(storage: locator<StandardStorageApi>()),
    );
  }
}
