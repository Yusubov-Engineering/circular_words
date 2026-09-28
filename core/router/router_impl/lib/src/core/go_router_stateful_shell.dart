import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:router_api/router_api.dart';

@internal
class GoRouterStatefulShell implements AppStatefulShell {
  const GoRouterStatefulShell(this._shell);

  final StatefulNavigationShell _shell;

  @override
  int get currentIndex => _shell.currentIndex;

  @override
  int get branchCount => _shell.route.branches.length;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    _shell.goBranch(index, initialLocation: initialLocation);
  }
}
