import 'package:rosco_api/rosco_api.dart';

import 'rosco_launcher_impl.dart';

/// The concrete facade registered into the container.
final class RoscoApiImpl({required final RoscoScoreboard _scoreboard})
    implements RoscoApi {
  @override
  RoscoLauncher get launcher => const RoscoLauncherImpl();

  @override
  RoscoScoreboard get scoreboard => _scoreboard;
}
