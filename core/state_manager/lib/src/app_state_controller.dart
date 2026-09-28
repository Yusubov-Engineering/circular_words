import 'dart:async';

import 'package:flutter/foundation.dart';

/// {@template app_state_controller}
/// The base engine for this app's State/Event/Effect pattern — a from
/// -scratch alternative to depending on packages like flutter_bloc,
/// riverpod, or provider.
///
/// A subclass exposes its business logic as a sealed event hierarchy
/// handled exhaustively in [onEvent], mutates the observable [state] via
/// [emit], and pushes one-shot side effects (navigation, dialogs, toasts,
/// ...) via [emitEffect].
///
/// * `S` — the observable, replayed state. Widgets read it through
///   AppControllerBuilder/AppControllerSelector.
/// * `E` — the events widgets [dispatch] into the controller.
/// * `F` — one-shot effects delivered through [effects] and handled by the
///   `onEffect` callback of `AppStateProvider`. Effects are **not replayed**,
///   so never emit one from a constructor: nothing is listening at that point
///   and the effect is silently dropped. [onInit] runs late enough to be
///   safe.
///
/// ### Example
///
/// ```dart
/// sealed class LoginState {
///   const LoginState();
/// }
/// final class LoginIdle extends LoginState {
///   const LoginIdle();
/// }
/// final class LoginSubmitting extends LoginState {
///   const LoginSubmitting();
/// }
///
/// sealed class LoginEvent {
///   const LoginEvent();
/// }
/// final class LoginSubmitted extends LoginEvent {
///   const LoginSubmitted();
/// }
///
/// sealed class LoginEffect {
///   const LoginEffect();
/// }
/// final class NavigateToDashboard extends LoginEffect {
///   const NavigateToDashboard();
/// }
///
/// final class LoginViewModel
///     extends AppStateController<LoginState, LoginEvent, LoginEffect> {
///   LoginViewModel() : super(const LoginIdle());
///
///   @override
///   Future<void> onEvent(LoginEvent event) async {
///     switch (event) {
///       case LoginSubmitted():
///         emit(const LoginSubmitting());
///         // await the real login call here, then:
///         emitEffect(const NavigateToDashboard());
///     }
///   }
/// }
/// ```
///
/// A screen provides the controller with `AppStateProvider`, handles its
/// effects through that provider's `onEffect`, and rebuilds on state with
/// `AppControllerBuilder`/`AppControllerSelector` — see each widget's doc
/// comment for a usage example.
/// {@endtemplate}
abstract class AppStateController<
  S extends Object,
  E extends Object,
  F extends Object
>
    extends ChangeNotifier {
  /// {@macro app_state_controller}
  AppStateController(this._state);

  S _state;
  final StreamController<F> _effects = StreamController<F>.broadcast();
  bool _isDisposed = false;

  /// The current, observable state.
  S get state => _state;

  /// One-shot effects emitted via [emitEffect]. Not replayed to listeners
  /// that subscribe after an effect has already been delivered.
  Stream<F> get effects => _effects.stream;

  /// Feeds [event] into the controller. Delegates to [onEvent] so the
  /// dispatch entry point stays fixed even as event handling evolves (e.g.
  /// adding cross-cutting logging around every dispatched event later).
  Future<void> dispatch(E event) => onEvent(event);

  /// One-time setup, called by `AppStateProvider` once the controller is
  /// mounted and its effect handler is already subscribed — the earliest
  /// point at which [emitEffect] is safe.
  ///
  /// Override it to kick off the screen's initial load. Do not call it
  /// yourself; the provider owns this call, exactly as it owns [dispose].
  Future<void> onInit() async {}

  /// Handles a dispatched [event]. Implement with an exhaustive
  /// `switch (event) { ... }` over a sealed `E` hierarchy, calling [emit]
  /// and/or [emitEffect] as needed.
  @protected
  Future<void> onEvent(E event);

  /// Updates [state] and notifies listeners.
  @protected
  void emit(S state) {
    if (_isDisposed) return;

    _state = state;
    notifyListeners();
  }

  /// Delivers a one-shot [effect] to any currently listening effect
  /// listener.
  @protected
  void emitEffect(F effect) {
    if (_isDisposed || _effects.isClosed) return;

    _effects.add(effect);
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    unawaited(_effects.close());
    super.dispose();
  }
}
