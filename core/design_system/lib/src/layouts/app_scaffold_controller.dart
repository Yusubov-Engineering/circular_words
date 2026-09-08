import 'package:material_ui/material_ui.dart';

/// {@template app_scaffold_controller}
/// Opens/closes the drawer(s) an `AppScaffold` hosts, programmatically.
///
/// Two ways to get one:
///
/// * `AppScaffoldController()` — created by whoever *builds* the `AppScaffold`
///   and passed to it via `AppScaffold.controller`. Same lifecycle as any
///   other Flutter controller (`TextEditingController`, `ScrollController`,
///   ...); no explicit disposal required.
/// * [AppScaffoldController.of] — binds to the nearest enclosing
///   `AppScaffold` instead, for widgets that live *inside* its subtree and so
///   can't be handed the controller its owner created (e.g. a screen rendered
///   into a shell route's body, whose drawer is owned by the shell).
/// {@endtemplate}
final class AppScaffoldController {
  /// {@macro app_scaffold_controller}
  AppScaffoldController()
    : scaffoldKey = GlobalKey<ScaffoldState>(),
      _boundState = null;

  AppScaffoldController._bound(ScaffoldState state)
    : scaffoldKey = null,
      _boundState = state;

  /// Binds to the nearest enclosing `AppScaffold`, so a descendant can drive
  /// a drawer it doesn't own. Throws if [context] has no `AppScaffold`
  /// ancestor, same as `Scaffold.of`.
  factory AppScaffoldController.of(BuildContext context) =>
      AppScaffoldController._bound(Scaffold.of(context));

  /// Wires this controller to the `Scaffold` an `AppScaffold` builds
  /// internally. Null for controllers created by [AppScaffoldController.of],
  /// which reach that state through the tree instead. Not meant to be used
  /// directly — go through the methods below.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  final ScaffoldState? _boundState;

  ScaffoldState? get _state => _boundState ?? scaffoldKey?.currentState;

  /// Whether the (start) drawer is currently open.
  bool get isDrawerOpen => _state?.isDrawerOpen ?? false;

  /// Whether the end drawer is currently open.
  bool get isEndDrawerOpen => _state?.isEndDrawerOpen ?? false;

  /// Opens the (start) drawer, if the `AppScaffold` has one.
  void openDrawer() => _state?.openDrawer();

  /// Opens the end drawer, if the `AppScaffold` has one.
  void openEndDrawer() => _state?.openEndDrawer();

  /// Closes the (start) drawer, if it's open.
  void closeDrawer() => _state?.closeDrawer();

  /// Closes the end drawer, if it's open.
  void closeEndDrawer() => _state?.closeEndDrawer();
}
