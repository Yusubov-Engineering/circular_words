import 'package:levels_api/levels_api.dart';

import 'levels_launcher_impl.dart';

/// The concrete facade registered into the container.
final class LevelsApiImpl implements LevelsApi {
  const LevelsApiImpl();

  @override
  LevelsLauncher get launcher => const LevelsLauncherImpl();
}
