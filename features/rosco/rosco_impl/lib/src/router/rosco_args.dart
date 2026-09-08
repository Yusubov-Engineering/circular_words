import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';

/// The level a round was entered at, parsed out of the path.
final class const RoscoArgs({required final CefrLevel level}) {
  /// Parses `/rosco/:level`.
  ///
  /// An unparseable level falls back to [CefrLevel.a1] rather than throwing:
  /// the segment is user-visible and hand-editable, and a typo should open the
  /// gentlest level rather than crash the router.
  factory RoscoArgs.fromRaw(AppRouteArguments raw) => RoscoArgs(
    level: CefrLevel.tryParse(raw.pathParameters['level']) ?? CefrLevel.a1,
  );
}
