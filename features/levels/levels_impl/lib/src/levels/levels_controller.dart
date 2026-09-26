import 'dart:async';

import 'package:analytics_api/analytics_api.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:state_manager/state_manager.dart';

import '../analytics/levels_analytics_events.dart';

/// One row on the picker: a level and whatever the player has managed on it.
final class const LevelEntry({
  required final CefrLevel level,
  final LevelScore? best,
}) {
  /// Whether this level has ever been finished.
  bool get isPlayed => best != null;
}

/// The observable state of the picker.
final class const LevelsState({
  final List<LevelEntry> entries = const [],
  final bool isLoading = true,
}) {
  LevelsState copyWith({List<LevelEntry>? entries, bool? isLoading}) =>
      LevelsState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// What the screen can ask the controller to do.
sealed class LevelsEvent {
  const LevelsEvent();
}

/// Re-reads the stored scores. Dispatched when returning from a round, which
/// is the only way a best score can have changed while this screen existed.
final class LevelsRefreshed extends LevelsEvent {
  const LevelsRefreshed();
}

final class const LevelSelected({required final CefrLevel level})
    extends LevelsEvent;

/// One-shot side effects: navigation, dialogs, toasts.
sealed class LevelsEffect {
  const LevelsEffect();
}

/// Leaves this feature. The controller only *asks* — the effect handler
/// resolves `RoscoApi` and lets that module say where its screens live.
final class const StartRound({required final CefrLevel level})
    extends LevelsEffect;

/// {@template levels_controller}
/// Holds the picker's state.
///
/// Takes the scoreboard in rather than reaching into the container, which is
/// what makes it testable with a fake.
/// {@endtemplate}
final class LevelsController
    extends AppStateController<LevelsState, LevelsEvent, LevelsEffect> {
  /// {@macro levels_controller}
  LevelsController({required this._scoreboard, required this._analytics})
    : super(const LevelsState());

  final RoscoScoreboard _scoreboard;
  final AnalyticsApi _analytics;

  @override
  Future<void> onInit() => _load();

  @override
  Future<void> onEvent(LevelsEvent event) async {
    switch (event) {
      case LevelsRefreshed():
        await _load();
      case LevelSelected(:final level):
        unawaited(_analytics.logEvent(LevelSelectedEvent(level: level)));
        emitEffect(StartRound(level: level));
    }
  }

  Future<void> _load() async {
    // Every level is always listed, played or not: the alphabet of levels is
    // fixed, and a missing score means "not played yet", never a missing row.
    var scores = <CefrLevel, LevelScore>{};
    try {
      scores = await _scoreboard.all();
    } on Object {
      // Unreadable scores degrade to an unplayed picker, not an error screen.
      scores = const {};
    }

    emit(
      state.copyWith(
        isLoading: false,
        entries: [
          for (final level in CefrLevel.values)
            LevelEntry(level: level, best: scores[level]),
        ],
      ),
    );
  }
}
