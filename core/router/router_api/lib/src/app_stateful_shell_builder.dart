import 'package:flutter/widgets.dart';

import 'app_stateful_shell.dart';

/// Signature for a function that builds a stateful shell (like a BottomNavigationBar)
/// wrapping the nested [child] router and providing a shell controller to switch tabs.
typedef AppStatefulShellBuilder = Widget Function(
  BuildContext context,
  AppStatefulShell appStatefullShell,
  Widget child,
);
