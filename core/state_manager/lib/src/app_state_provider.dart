import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_state_controller.dart';

/// {@template app_state_provider}
/// Owns one [AppStateController] for the lifetime of a screen: creates it,
/// calls its `onInit`, routes its effects to [onEffect], disposes it, and
/// exposes it to descendants — read it back with
/// `context.controllerOf<C>()`, or let `AppControllerBuilder` find it.
///
/// Unlike an app-wide scope wired once in bootstrap, this widget owns a
/// per-screen lifecycle: place it at the root of a screen so the controller
/// is created when the screen mounts and disposed when it's popped.
///
/// ```dart
/// class LoginScreen extends StatelessWidget {
///   const LoginScreen({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return AppStateProvider(
///       create: LoginViewModel.new,
///       onEffect: _onEffect,
///       child: const _LoginView(),
///     );
///   }
///
///   void _onEffect(BuildContext context, LoginEffect effect) {
///     switch (effect) {
///       case NavigateToDashboard():
///         context.navigation.goRoute(AppRoutes.home.dashboard());
///     }
///   }
/// }
/// ```
///
/// Two rules make the inference work:
///
/// * **Never write the type arguments out.** All four are inferred from
///   `create`, and naming only the controller is a compile error — Dart has
///   no partial type arguments.
/// * **Pass [onEffect] a named method with an explicit effect parameter**, as
///   above. An inline closure infers its parameter as `Object?`, which turns
///   the exhaustive `switch` into a non-exhaustive one with no error to show
///   for it — and annotating a closure parameter is itself banned by
///   `avoid_types_on_closure_parameters`, so the named method is the only
///   form that is both correct and lint-clean.
/// {@endtemplate}
class const AppStateProvider<
  C extends AppStateController<S, E, F>,
  S extends Object,
  E extends Object,
  F extends Object
>({
  required final C Function() create,
  required final Widget child,
  final void Function(BuildContext context, F effect)? onEffect,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppStateProvider<C, S, E, F>> createState() =>
      _AppStateProviderState<C, S, E, F>();

  /// Returns the nearest [C] controller provided by an ancestor
  /// [AppStateProvider]. Prefer `context.controllerOf<C>()`.
  static C of<C extends AppStateController<Object, Object, Object>>(
    BuildContext context,
  ) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_AppStateScope<C>>();
    assert(scope != null, 'No AppStateProvider<$C> found in context');
    return scope!.controller;
  }
}

class _AppStateProviderState<
  C extends AppStateController<S, E, F>,
  S extends Object,
  E extends Object,
  F extends Object
>
    extends State<AppStateProvider<C, S, E, F>> {
  late final C _controller = widget.create();
  StreamSubscription<F>? _subscription;

  @override
  void initState() {
    super.initState();

    // Subscribe before onInit so an effect emitted during startup still has
    // a listener. The stream is async, so delivery lands after this frame is
    // scheduled either way.
    _subscription = _controller.effects.listen(_onEffect);
    unawaited(_controller.onInit());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _controller.dispose();
    super.dispose();
  }

  void _onEffect(F effect) {
    if (!mounted) return;

    widget.onEffect?.call(context, effect);
  }

  @override
  Widget build(BuildContext context) {
    return _AppStateScope<C>(controller: _controller, child: widget.child);
  }
}

class const _AppStateScope<
  C extends AppStateController<Object, Object, Object>
>({required final C controller, required super.child}) extends InheritedWidget {
  @override
  bool updateShouldNotify(_AppStateScope<C> oldWidget) =>
      controller != oldWidget.controller;
}
