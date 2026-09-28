import 'package:flutter/widgets.dart';

import 'app_state_controller.dart';
import 'app_state_provider.dart';

/// {@template app_controller_builder}
/// Rebuilds its subtree whenever the nearest [C] controller's state changes.
///
/// The controller is looked up from the enclosing [AppStateProvider], so the
/// only type argument is the controller itself. [builder] receives that
/// controller: read `controller.state` for the current state, and call
/// `controller.dispatch(...)` without a separate lookup.
///
/// ```dart
/// AppControllerBuilder<LoginViewModel>(
///   builder: (context, controller) => AppPrimaryButton(
///     enabled: controller.state is! LoginSubmitting,
///     onTap: () => controller.dispatch(const LoginSubmitted()),
///     title: context.localization.login,
///   ),
/// )
/// ```
///
/// This rebuilds on *every* state change. To rebuild only when one slice of
/// the state changes, use `AppControllerSelector` instead.
/// {@endtemplate}
class const AppControllerBuilder<
  C extends AppStateController<Object, Object, Object>
>({
  required final Widget Function(BuildContext context, C controller) builder,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppControllerBuilder<C>> createState() =>
      _AppControllerBuilderState<C>();
}

class _AppControllerBuilderState<
  C extends AppStateController<Object, Object, Object>
>
    extends State<AppControllerBuilder<C>> {
  C? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = AppStateProvider.of<C>(context);
    if (identical(controller, _controller)) return;

    _controller?.removeListener(_onControllerChanged);
    _controller = controller..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller!);
}
