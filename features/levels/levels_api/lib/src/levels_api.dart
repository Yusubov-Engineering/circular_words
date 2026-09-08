import 'levels_launcher.dart';

/// {@template levels_api}
/// Everything other modules may use from the Levels feature.
///
/// Other packages depend on `levels_api` and resolve this with
/// `context.locator<LevelsApi>()`, never on `levels_impl`.
///
/// Use case protocols belong here too, as they appear.
/// {@endtemplate}
abstract interface class LevelsApi {
  /// Route requests into this feature.
  LevelsLauncher get launcher;
}
