import 'rosco_launcher.dart';
import 'rosco_scoreboard.dart';

/// {@template rosco_api}
/// Everything other modules may use from the Rosco feature.
///
/// Other packages depend on `rosco_api` and resolve this with
/// `context.locator<RoscoApi>()`, never on `rosco_impl`.
/// {@endtemplate}
abstract interface class RoscoApi {
  /// Route requests into this feature.
  RoscoLauncher get launcher;

  /// Best results per level, for anyone showing progress.
  RoscoScoreboard get scoreboard;
}
