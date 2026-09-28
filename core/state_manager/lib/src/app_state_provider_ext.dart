import 'package:flutter/widgets.dart';

import 'app_state_controller.dart';
import 'app_state_provider.dart';

/// Convenience access to the nearest [AppStateProvider]'s controller, e.g.
/// `context.controllerOf<LoginViewModel>()`.
extension AppStateProviderExt on BuildContext {
  C controllerOf<C extends AppStateController<Object, Object, Object>>() =>
      AppStateProvider.of<C>(this);
}
