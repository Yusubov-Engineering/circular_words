import 'package:flutter/widgets.dart';

import '../tokens/colors/app_accent_color_tokens.dart';

/// {@template app_accent_scope}
/// Re-tints everything below it with [accent].
///
/// The one knob for colouring part of the app: wrap a screen, a card or a
/// single control, and every component under it that reads
/// `context.accentColors` follows — in light and dark alike, since the
/// tokens are resolved against the theme's brightness at read time.
/// {@endtemplate}
class const AppAccentScope({
  required final AppAccent accent,
  required super.child,
  super.key,
}) extends InheritedWidget {
  /// The accent of the nearest scope, or `null` when there is none and the
  /// theme's own accent applies.
  static AppAccent? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppAccentScope>()?.accent;

  @override
  bool updateShouldNotify(AppAccentScope oldWidget) =>
      oldWidget.accent != accent;
}
