import 'package:flutter/widgets.dart';

import 'app_state_controller.dart';
import 'app_state_provider.dart';

/// {@template app_controller_selector}
/// Rebuilds its subtree only when [select] returns a different value —
/// the precise form of "rebuild for this part of the state, ignore the rest".
///
/// Like `AppControllerBuilder`, the controller comes from the enclosing
/// [AppStateProvider]. [select] must be cheap and free of side effects: it
/// runs on every state change.
///
/// ```dart
/// AppControllerSelector<LoginViewModel, bool>(
///   select: (controller) => controller.state is LoginSubmitting,
///   builder: (context, isSubmitting) => AppPrimaryButton(
///     enabled: !isSubmitting,
///     onTap: () => context
///         .controllerOf<LoginViewModel>()
///         .dispatch(const LoginSubmitted()),
///     title: context.localization.login,
///   ),
/// )
/// ```
///
/// Values are compared with `==`, so select a primitive or a value type —
/// selecting a freshly built list or a class without `==` rebuilds every
/// time and defeats the purpose.
/// {@endtemplate}
class const AppControllerSelector<
  C extends AppStateController<Object, Object, Object>,
  T
>({
  required final T Function(C controller) select,
  required final Widget Function(BuildContext context, T value) builder,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppControllerSelector<C, T>> createState() =>
      _AppControllerSelectorState<C, T>();
}

class _AppControllerSelectorState<
  C extends AppStateController<Object, Object, Object>,
  T
>
    extends State<AppControllerSelector<C, T>> {
  C? _controller;
  late T _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = AppStateProvider.of<C>(context);
    if (identical(controller, _controller)) return;

    _controller?.removeListener(_onControllerChanged);
    _controller = controller..addListener(_onControllerChanged);
    _value = widget.select(controller);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final value = widget.select(_controller!);
    if (value == _value) return;

    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
